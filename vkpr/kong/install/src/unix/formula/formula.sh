#!/bin/sh

runFormula() {
  local VKPR_KONG_VALUES=$(dirname "$0")/utils/kong.yaml
  local VKPR_KONG_DP_VALUES=$(dirname "$0")/utils/kong-dp.yaml
  
  checkGlobalConfig $DOMAIN "localhost" "domain" "DOMAIN"
  checkGlobalConfig $SECURE "false" "secure" "SECURE"
  checkGlobalConfig $HA "false" "kong.HA" "HA"
  checkGlobalConfig "false" "false" "kong.metrics" "METRICS"
  checkGlobalConfig $KONG_MODE "kong" "kong.mode" "KONG_DEPLOY"
  checkGlobalConfig $RBAC_PASSWORD "vkpr123" "kong.rbac.password" "KONG_RBAC"

  startInfos
  addRepoKong
  addDependencies
  [[ $VKPR_ENV_KONG_DEPLOY != "dbless" ]] && installDB
  [[ $ENTERPRISE = true ]] && createKongSecrets
  installKong
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Kong Install Routine")"
  echoColor "bold" "$(echoColor "blue" "Kong HTTPS:") ${VKPR_ENV_SECURE}"
  echoColor "bold" "$(echoColor "blue" "Kong Domain:") ${VKPR_ENV_DOMAIN}"
  echoColor "bold" "$(echoColor "blue" "Kong HA:") ${VKPR_ENV_HA}"
  echoColor "bold" "$(echoColor "blue" "Kong Mode:") ${VKPR_ENV_KONG_DEPLOY}"
  echo "=============================="
}

addRepoKong(){
  registerHelmRepository kong https://charts.konghq.com
}

addDependencies(){
  mkdir -p config/
  echo '{"cookie_name":"admin_session","cookie_samesite":"Strict","secret":"admin-cookie-secret","cookie_secure":false,"storage":"kong","cookie_domain":"manager.'$VKPR_ENV_DOMAIN'"}' > config/admin_gui_session_conf
  echo '{"cookie_name":"portal_session","cookie_samesite":"Strict","secret":"portal-cookie-secret","cookie_secure":false,"storage":"kong","cookie_domain":"portal.'$VKPR_ENV_DOMAIN'"}' > config/portal_session_conf
  if [[ $VKPR_ENV_KONG_DEPLOY = "hybrid" ]]; then
    openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
                -keyout config/cluster.key -out config/cluster.crt \
                -days 1095 -subj "/CN=kong_clustering"
  fi
}

createKongSecrets() {
  local LICENSE_CONTENT=$(cat $LICENSE)
  echoColor "green" "Creating the Kong Secrets..."
  $VKPR_KUBECTL create ns vkpr 2> /dev/null
  $VKPR_KUBECTL create secret generic kong-enterprise-license --from-literal="license=$LICENSE_CONTENT" -n $VKPR_K8S_NAMESPACE
  if [[ $VKPR_ENV_KONG_DEPLOY != "dbless" ]]; then
    $VKPR_KUBECTL create secret generic kong-session-config \
      --from-file=config/admin_gui_session_conf \
      --from-file=config/portal_session_conf -n $VKPR_K8S_NAMESPACE
  fi
  if [[ $VKPR_ENV_KONG_DEPLOY = "hybrid" ]]; then
    $VKPR_KUBECTL create ns kong
    $VKPR_KUBECTL create secret tls kong-cluster-cert --cert=config/cluster.crt --key=config/cluster.key -n $VKPR_K8S_NAMESPACE
    $VKPR_KUBECTL create secret tls kong-cluster-cert --cert=config/cluster.crt --key=config/cluster.key -n kong
    $VKPR_KUBECTL create secret generic kong-enterprise-license --from-file=$LICENSE -n kong
  fi
  rm -rf $(dirname "$0")/config/
}

installDB(){
  local PG_HA="false"
  [[ $VKPR_ENV_HA == true ]] && PG_HA="true"
  if [[ $(checkPodName "postgres-postgresql") != "true" ]]; then
    echoColor "green" "Initializing postgresql to Kong"
    rit vkpr postgres install --HA=$PG_HA --default
  else
    echoColor "green" "Initializing Kong with Postgres already created"
  fi
}

installKong(){
  local YQ_VALUES=".proxy.enabled = true"
  settingKongEnterprise
  if [[ $VKPR_ENV_KONG_DEPLOY = "hybrid" ]]; then
    echoColor "bold" "$(echoColor "green" "Installing Kong DP in cluster...")"
    $VKPR_YQ eval "$YQ_VALUES" "$VKPR_KONG_DP_VALUES" \
    | $VKPR_HELM upgrade -i --wait -n kong \
        --version $VKPR_KONG_VERSION -f - kong-dp kong/kong
  fi

  settingKongDefaults
  case $VKPR_ENV_KONG_DEPLOY in
    hybrid)
      VKPR_KONG_VALUES=$(dirname "$0")/utils/kong-cp.yaml
    ;;
    dbless)
      VKPR_KONG_VALUES=$(dirname "$0")/utils/kong-dbless.yaml
    ;;
  esac

  echoColor "bold" "$(echoColor "green" "Installing Kong...")"
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_KONG_VALUES" \
  | $VKPR_HELM upgrade -i --wait --create-namespace -n $VKPR_K8S_NAMESPACE \
      --version $VKPR_KONG_VERSION -f - kong kong/kong
  [[ $VKPR_ENV_METRICS == "true" ]] && $VKPR_KUBECTL apply -f $(dirname "$0")/utils/prometheus-plugin.yaml
}

settingKongDefaults() {
  local PG_HOST="postgres-postgresql"
  [[ ! -z $($VKPR_KUBECTL get pod -n $VKPR_K8S_NAMESPACE | grep pgpool) ]] && PG_HOST="postgres-postgresql-pgpool" YQ_VALUES=''$YQ_VALUES' | .env.pg_password.valueFrom.secretKeyRef.name = "postgres-postgresql-postgresql"'
  YQ_VALUES=''$YQ_VALUES' |
    .env.pg_host = "'$PG_HOST'"
  '

  if [[ $VKPR_ENV_DOMAIN != "localhost" ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .admin.ingress.hostname = "'api.manager.$VKPR_ENV_DOMAIN'" |
      .manager.ingress.hostname = "'manager.$VKPR_ENV_DOMAIN'" |
      .env.admin_gui_url="'http://manager.$VKPR_ENV_DOMAIN'" |
      .env.admin_api_uri="'http://api.manager.$VKPR_ENV_DOMAIN'"|
      .env.portal_gui_host="'http://portal.$VKPR_ENV_DOMAIN'" |
      .env.portal_api_url="'http://api.portal.$VKPR_ENV_DOMAIN'"
    '
    if [[ $VKPR_ENV_SECURE = true ]]; then
      YQ_VALUES=''$YQ_VALUES' |
        .admin.ingress.annotations.["'kubernetes.io/tls-acme'"] = "'true'" |
        .admin.ingress.tls = "admin-kong-cert" |
        .manager.ingress.annotations.["'kubernetes.io/tls-acme'"] = "'true'" |
        .manager.ingress.tls = "manager-kong-cert" |
        .env.portal_gui_protocol = "https" |
        .env.admin_gui_url="'https://manager.$VKPR_ENV_DOMAIN'" |
        .env.admin_api_uri="'https://api.manager.$VKPR_ENV_DOMAIN'"|
        .env.portal_gui_host="'https://portal.$VKPR_ENV_DOMAIN'" |
        .env.portal_api_url="'https://api.portal.$VKPR_ENV_DOMAIN'"
      '
    fi
  fi
  if [[ $VKPR_ENV_KONG_DEPLOY != "dbless" ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .portal.ingress.annotations.["'kubernetes.io/tls-acme'"] = "'true'" |
      .portal.ingress.tls = "portal-kong-cert" |
      .portalapi.ingress.annotations.["'kubernetes.io/tls-acme'"] = "'true'" |
      .portalapi.ingress.tls = "portalapi-kong-cert"
    '
  fi
  if [[ $VKPR_ENV_METRICS == "true" ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .serviceMonitor.enabled = true |
      .serviceMonitor.namespace = "vkpr" |
      .serviceMonitor.interval = "30s" |
      .serviceMonitor.scrapeTimeout = "30s" |
      .serviceMonitor.labels.release = "prometheus-stack" |
      .serviceMonitor.targetLabels[0] = "prometheus-stack"
    '
  fi
  if [[ $VKPR_ENV_HA == "true" ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .replicaCount = 3 |
      .ingressController.env.leader_elect = "true"
    '
  fi
  if [[ $ENTERPRISE = true ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .env.enforce_rbac = "on" |
      .env.password.valueFrom.secretKeyRef.name = "kong-enterprise-superuser-password" |
      .env.password.valueFrom.secretKeyRef.key = "password" |
      .ingressController.env.kong_admin_token.valueFrom.secretKeyRef.name = "kong-enterprise-superuser-password" |
      .ingressController.env.kong_admin_token.valueFrom.secretKeyRef.key = "password" |
      .enteprise.rbac.enabled = "true" |
      .enteprise.rbac.admin_gui_auth = "basic-auth" |
      .enteprise.rbac.session_conf_secret = "kong-session-config"
    '
  fi
  mergeVkprValuesHelmArgs "kong" $VKPR_KONG_VALUES
}

settingKongEnterprise() {
  $VKPR_KUBECTL create secret generic kong-enterprise-superuser-password -n $VKPR_K8S_NAMESPACE --from-literal="password=$VKPR_ENV_KONG_RBAC"
  if [[ $ENTERPRISE = true ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .image.repository = "kong/kong-gateway" |
      .image.tag = "2.7.0.0-alpine" |
      .enterprise.enabled = true |
      .enterprise.vitals.enabled = true |
      .enterprise.portal.enabled = true |
      .env.enforce_rbac = "on" |
      .env.password.valueFrom.secretKeyRef.name = "kong-enterprise-superuser-password" |
      .env.password.valueFrom.secretKeyRef.key = "password" |
      .ingressController.env.kong_admin_token.valueFrom.secretKeyRef.name = "kong-enterprise-superuser-password" |
      .ingressController.env.kong_admin_token.valueFrom.secretKeyRef.key = "password" |
      .enteprise.rbac.enabled = "true" |
      .enteprise.rbac.admin_gui_auth = "basic-auth" |
      .enteprise.rbac.session_conf_secret = "kong-session-config"
    '
  fi
}