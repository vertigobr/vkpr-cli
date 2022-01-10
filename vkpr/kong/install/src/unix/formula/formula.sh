#!/bin/sh

runFormula() {
  local VKPR_KONG_VALUES=$(dirname "$0")/utils/kong.yaml
  local VKPR_KONG_DP_VALUES=$(dirname "$0")/utils/kong-dp.yaml
  
  checkGlobalConfig $DOMAIN "localhost" "domain" "DOMAIN"
  checkGlobalConfig $SECURE "false" "secure" "SECURE"
  checkGlobalConfig "false" "false" "kong.HA" "HA"
  checkGlobalConfig "false" "false" "kong.metrics" "METRICS"
  checkGlobalConfig $KONG_MODE "kong" "kong.mode" "KONG_DEPLOY"

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
  echo '{"cookie_name":"admin_session","cookie_samesite":"off","secret":"manager12345","cookie_secure":false,"storage":"kong"}' > config/admin_gui_session_conf
  echo '{"cookie_name":"portal_session","cookie_samesite":"off","secret":"portal12345","cookie_secure":false,"storage":"kong"}' > config/portal_session_conf
  if [[ $VKPR_ENV_KONG_DEPLOY = "hybrid" ]]; then
    openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
                -keyout config/cluster.key -out config/cluster.crt \
                -days 1095 -subj "/CN=kong_clustering"
  fi
}

createKongSecrets() {
  echoColor "green" "Creating the Kong Secrets..."
  $VKPR_KUBECTL create ns vkpr 2> /dev/null
  $VKPR_KUBECTL create secret generic kong-enterprise-license --from-file=$LICENSE -n vkpr
  if [[ $VKPR_ENV_KONG_DEPLOY != "dbless" ]]; then
    $VKPR_KUBECTL create secret generic kong-session-config \
      --from-file=config/admin_gui_session_conf \
      --from-file=config/portal_session_conf -n vkpr
  fi
  if [[ $VKPR_ENV_KONG_DEPLOY = "hybrid" ]]; then
    $VKPR_KUBECTL create ns kong
    $VKPR_KUBECTL create secret tls kong-cluster-cert --cert=config/cluster.crt --key=config/cluster.key -n vkpr
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
        --version 2.6.0 -f - kong-dp kong/kong
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
  | $VKPR_HELM upgrade -i --wait --create-namespace -n vkpr \
      --version 2.6.0 -f - kong kong/kong
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
      .admin.ingress.hostname = "'admin.$VKPR_ENV_DOMAIN'" |
      .manager.ingress.hostname = "'manager.$VKPR_ENV_DOMAIN'" |
      .env.admin_gui_url="'http://manager.$VKPR_ENV_DOMAIN'" |
      .env.admin_api_uri="'http://admin.$VKPR_ENV_DOMAIN'"
    '
  fi
  if [[ $VKPR_ENV_SECURE = true ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .admin.ingress.annotations.["'kubernetes.io/tls-acme'"] = "'true'" |
      .admin.ingress.tls = "admin-kong-cert" |
      .manager.ingress.annotations.["'kubernetes.io/tls-acme'"] = "'true'" |
      .manager.ingress.tls = "manager-kong-cert"
    '
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

  mergeVkprValuesHelmArgs "kong" $VKPR_KONG_VALUES
}

settingKongEnterprise() {
  if [[ $ENTERPRISE = true ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .image.repository = "kong/kong-gateway" |
      .image.tag = "2.6.0.0-alpine" |
      .enterprise.enabled = true |
      .enterprise.vitals.enabled = true |
      .enterprise.portal.enabled = true
    '
  fi
}