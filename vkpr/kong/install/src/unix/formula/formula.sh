#!/bin/bash

runFormula() {
  # Global values
  checkGlobalConfig "$DOMAIN" "localhost" "global.domain" "GLOBAL_DOMAIN"
  checkGlobalConfig "$SECURE" "false" "global.secure" "GLOBAL_SECURE"
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "global.namespace" "GLOBAL_NAMESPACE"
  
  # App values
  checkGlobalConfig "$HA" "false" "kong.HA" "KONG_HA"
  checkGlobalConfig "false" "false" "kong.metrics" "KONG_METRICS"
  checkGlobalConfig "$KONG_MODE" "dbless" "kong.mode" "KONG_MODE"
  checkGlobalConfig "$RBAC_PASSWORD" "vkpr123" "kong.rbac.adminPassword" "KONG_RBAC_ADMIN_PASSWORD"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "kong.namespace" "KONG_NAMESPACE"
  checkGlobalConfig "false" "false" "kong.vitals.prometheusStrategy" "KONG_VITALS_STRATEGY"

  # External apps values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "postgresql.namespace" "POSTGRESQL_NAMESPACE"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "PROMETHEUS_STACK_NAMESPACE" 

  local VKPR_KONG_VALUES; VKPR_KONG_VALUES="$(dirname "$0")"/utils/kong.yaml

  [[ $DRY_RUN == true ]] && DRY_RUN_FLAGS="--dry-run=client -o yaml"

  startInfos
  addRepoKong
  addDependencies
  [[ "$VKPR_ENV_KONG_MODE" != "dbless" ]] && installDB
  [[ "$ENTERPRISE" == true ]] && createKongSecrets
  installKong
}

startInfos() {
  echo "=============================="
  info "VKPR Kong Install Routine"
  notice "Kong HTTPS: ${VKPR_ENV_GLOBAL_SECURE}"
  notice "Kong Domain: ${VKPR_ENV_GLOBAL_DOMAIN}"
  notice "Kong HA: ${VKPR_ENV_KONG_HA}"
  notice "Kong Mode: ${VKPR_ENV_KONG_MODE}"
  echo "=============================="
}

addRepoKong(){
  registerHelmRepository kong https://charts.konghq.com
}

addDependencies(){
  mkdir -p /tmp/config/
  printf "{
  \"cookie_name\": \"admin_session\",
  \"cookie_samesite\": \"off\",
  \"secret\": \"$(openssl rand -base64 32)\",
  \"cookie_secure\": false,
  \"storage\": \"kong\",
  \"cookie_domain\": \"manager.%s\"
}" "$VKPR_ENV_GLOBAL_DOMAIN" > /tmp/config/admin_gui_session_conf

  printf "{
  \"cookie_name\": \"portal_session\",
  \"cookie_samesite\": \"off\",
  \"secret\": \"$(openssl rand -base64 32)\",
  \"cookie_secure\": false,
  \"storage\": \"kong\",
  \"cookie_domain\": \"portal.%s\"
}" "$VKPR_ENV_GLOBAL_DOMAIN" > /tmp/config/portal_session_conf

  if [[ "$VKPR_ENV_KONG_MODE" == "hybrid" ]]; then
    openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
                -keyout config/cluster.key -out /tmp/config/cluster.crt \
                -days 1095 -subj "/CN=kong_clustering"
  fi
}

createKongSecrets() {
  info "Creating the Kong Secrets..."
  $VKPR_KUBECTL create ns "$VKPR_ENV_KONG_NAMESPACE" 2> /dev/null

  [[ "$LICENSE" == " " ]] && LICENSE="license"
  local LICENSE_CONTENT; LICENSE_CONTENT=$(cat "$LICENSE" 2> /dev/null)
  $VKPR_KUBECTL create secret generic kong-enterprise-license --from-literal="license=$LICENSE_CONTENT" -n "$VKPR_ENV_KONG_NAMESPACE" $DRY_RUN_FLAGS && \
  $VKPR_KUBECTL label secret kong-enterprise-license vkpr=true app.kubernetes.io/instance=kong -n "$VKPR_ENV_KONG_NAMESPACE" 2> /dev/null

  if [[ "$VKPR_ENV_KONG_MODE" != "dbless" ]]; then
    $VKPR_KUBECTL create secret generic kong-session-config \
      --from-file=/tmp/config/admin_gui_session_conf \
      --from-file=/tmp/config/portal_session_conf -n "$VKPR_ENV_KONG_NAMESPACE" $DRY_RUN_FLAGS && \
    $VKPR_KUBECTL label secret kong-session-config vkpr=true app.kubernetes.io/instance=kong -n "$VKPR_ENV_KONG_NAMESPACE" 2> /dev/null
  fi

  if [[ "$VKPR_ENV_KONG_MODE" = "hybrid" ]]; then
    $VKPR_KUBECTL create ns kong

    $VKPR_KUBECTL create secret tls kong-cluster-cert --cert=/tmp/config/cluster.crt --key=/tmp/config/cluster.key -n "$VKPR_ENV_KONG_NAMESPACE" $DRY_RUN_FLAGS && $VKPR_KUBECTL label secret kong-cluster-cert vkpr=true app.kubernetes.io/instance=kong -n "$VKPR_ENV_KONG_NAMESPACE" 2> /dev/null

    $VKPR_KUBECTL create secret tls kong-cluster-cert --cert=/tmp/config/cluster.crt --key=/tmp/config/cluster.key -n kong $DRY_RUN_FLAGS && \
    $VKPR_KUBECTL label secret kong-cluster-cert vkpr=true app.kubernetes.io/instance=kong -n kong 2> /dev/null

    $VKPR_KUBECTL create secret generic kong-enterprise-license --from-file=$LICENSE -n kong $DRY_RUN_FLAGS && \
      $VKPR_KUBECTL label secret kong-enterprise-license vkpr=true app.kubernetes.io/instance=kong -n kong 2> /dev/null
  fi

  rm -rf /tmp/config/
}

installDB(){
  local PG_HA="false"
  [[ $VKPR_ENV_KONG_HA == true ]] && PG_HA="true"

  if [[ $(checkPodName "$VKPR_ENV_POSTGRESQL_NAMESPACE" "postgres-postgresql") != "true" ]]; then
    info "Initializing postgresql to Kong"
    [[ -f $CURRENT_PWD/vkpr.yaml ]] && cp "$CURRENT_PWD"/vkpr.yaml "$(dirname "$0")"
    rit vkpr postgres install --HA=$PG_HA --dry_run=$DRY_RUN --default
  else
    info "Initializing Kong with Postgres already created"
  fi
}

installKong(){
  local YQ_VALUES=".proxy.enabled = true"

  case "$VKPR_ENV_KONG_MODE" in
    hybrid)
      installKongDP
      VKPR_KONG_VALUES="$(dirname "$0")"/utils/kong-cp.yaml
    ;;
    dbless)
      VKPR_KONG_VALUES="$(dirname "$0")"/utils/kong-dbless.yaml
    ;;
  esac
  settingKongDefaults

  if [[ $DRY_RUN == true ]]; then
    echoColor "bold" "---"
    $VKPR_YQ eval "$YQ_VALUES" "$VKPR_KONG_VALUES"
  else
    info "Installing Kong..."
    $VKPR_YQ eval -i "$YQ_VALUES" "$VKPR_KONG_VALUES"
    mergeVkprValuesHelmArgs "kong" "$VKPR_KONG_VALUES"
    $VKPR_HELM upgrade -i --version "$VKPR_KONG_VERSION" \
      --namespace "$VKPR_ENV_KONG_NAMESPACE" --create-namespace \
      --wait -f "$VKPR_KONG_VALUES" kong kong/kong
  fi

  if [[ "$VKPR_ENV_KONG_METRICS" == true ]]; then
    echoColor "bold" "Setting prometheus plugins..."
    $VKPR_KUBECTL apply -f "$(dirname "$0")"/utils/prometheus-plugin.yaml $DRY_RUN_FLAGS
  fi
}

installKongDP() {
  local VKPR_KONG_DP_VALUES; VKPR_KONG_DP_VALUES="$(dirname "$0")"/utils/kong-dp.yaml

  if [[ $DRY_RUN == true ]]; then
    echoColor "bold" "---"
    $VKPR_YQ eval "$YQ_VALUES" "$VKPR_KONG_DP_VALUES"
  else
    info "Installing Kong DP in cluster..."
    $VKPR_YQ eval "$YQ_VALUES" "$VKPR_KONG_DP_VALUES" \
    | $VKPR_HELM upgrade -i --version "$VKPR_KONG_VERSION" \
      --namespace kong --create-namespace \
      --wait -f - kong-dp kong/kong
  fi
}

settingKongDefaults() {
  settingKongEnterprise
  settingKongDB

  if [[ "$VKPR_ENV_GLOBAL_DOMAIN" != "localhost" ]]; then
    YQ_VALUES="$YQ_VALUES |
      .admin.ingress.hostname = \"api.manager.$VKPR_ENV_GLOBAL_DOMAIN\" |
      .manager.ingress.hostname = \"manager.$VKPR_ENV_GLOBAL_DOMAIN\" |
      .portal.ingress.hostname = \"portal.$VKPR_ENV_GLOBAL_DOMAIN\" |
      .portalapi.ingress.hostname = \"api.portal.$VKPR_ENV_GLOBAL_DOMAIN\" |
      .env.admin_gui_url = \"http://manager.$VKPR_ENV_GLOBAL_DOMAIN\" |
      .env.admin_api_uri = \"http://api.manager.$VKPR_ENV_GLOBAL_DOMAIN\"|
      .env.portal_gui_host = \"http://portal.$VKPR_ENV_GLOBAL_DOMAIN\" |
      .env.portal_api_url = \"http://api.portal.$VKPR_ENV_GLOBAL_DOMAIN\"
    "

    if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
      YQ_VALUES="$YQ_VALUES |
        .admin.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
        .admin.ingress.tls = \"admin-kong-cert\" |
        .manager.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
        .manager.ingress.tls = \"manager-kong-cert\" |
        .env.admin_gui_url = \"https://manager.$VKPR_ENV_GLOBAL_DOMAIN\" |
        .env.admin_api_uri = \"https://api.manager.$VKPR_ENV_GLOBAL_DOMAIN\"
      "
      if [[ "$VKPR_ENV_KONG_MODE" != "dbless" ]]; then
        YQ_VALUES="$YQ_VALUES |
          .env.portal_gui_protocol = \"https\" |
          .env.portal_gui_host = \"portal.$VKPR_ENV_GLOBAL_DOMAIN\" |
          .env.portal_api_url = \"https://api.portal.$VKPR_ENV_GLOBAL_DOMAIN\" |
          .portal.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
          .portal.ingress.tls = \"portal-kong-cert\" |
          .portalapi.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
          .portalapi.ingress.tls = \"portalapi-kong-cert\"
        "
      fi
    fi
  fi

  if [[ "$VKPR_ENV_KONG_METRICS" == "true" ]]; then
    YQ_VALUES="$YQ_VALUES |
      .serviceMonitor.enabled = \"true\" |
      .serviceMonitor.namespace = \"$VKPR_ENV_KONG_NAMESPACE\" |
      .serviceMonitor.interval = \"30s\" |
      .serviceMonitor.scrapeTimeout = \"30s\" |
      .serviceMonitor.labels.release = \"prometheus-stack\" |
      .serviceMonitor.targetLabels[0] = \"prometheus-stack\"
    "
      if [[ "$VKPR_ENV_KONG_VITALS_STRATEGY" == "true" ]] && [[ $(checkPodName "$VKPR_ENV_PROMETHEUS_STACK_NAMESPACE" "prometheus-stack-kube-prom-operator") == "true" ]]; then
        YQ_VALUES="$YQ_VALUES |
          .env.vitals = \"on\" |
          .env.vitals_strategy = \"prometheus\" |
          .env.vitals_statsd_address = \"statsd-kong:9125\" |
          .env.vitals_tsdb_address = \"prometheus-stack-kube-prom-prometheus:9090\" |      
          .env.vitals_statsd_prefix = \"kong-vitals\" 
        "
        $VKPR_KUBECTL apply -f "$(dirname "$0")/utils/kong-service-monitor.yaml"
      fi
  fi

  if [[ "$VKPR_ENV_KONG_HA" == "true" ]]; then
    YQ_VALUES="$YQ_VALUES |
      .replicaCount = \"3\" |
      .ingressController.env.leader_elect = \"true\"
    "
  fi
}

settingKongEnterprise() {
  if [[ "$ENTERPRISE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .image.repository = \"kong/kong-gateway\" |
      .image.tag = \"2.7.1.2-alpine\" |
      .enterprise.enabled = \"true\" |
      .enterprise.vitals.enabled = \"true\" |
      .enterprise.portal.enabled = \"true\"
    "

    if [[ "$VKPR_ENV_KONG_MODE" != "dbless" ]]; then
      YQ_VALUES="$YQ_VALUES |
        .env.password.valueFrom.secretKeyRef.name = \"kong-enterprise-superuser-password\" |
        .env.password.valueFrom.secretKeyRef.key = \"password\" |
        .ingressController.env.kong_admin_token.valueFrom.secretKeyRef.name = \"kong-enterprise-superuser-password\" |
        .ingressController.env.kong_admin_token.valueFrom.secretKeyRef.key = \"password\" |
        .enterprise.rbac.enabled = \"true\" |
        .enterprise.rbac.admin_gui_auth = \"basic-auth\" |
        .enterprise.rbac.session_conf_secret = \"kong-session-config\" |
        .env.enforce_rbac = \"on\" |
        .env.enforce_rbac style=\"double\"
      "
      $VKPR_KUBECTL create secret generic kong-enterprise-superuser-password --from-literal="password=$VKPR_ENV_KONG_RBAC_ADMIN_PASSWORD" -n "$VKPR_ENV_KONG_NAMESPACE" $DRY_RUN_FLAGS && $VKPR_KUBECTL label secret kong-enterprise-superuser-password vkpr=true app.kubernetes.io/instance=kong -n "$VKPR_ENV_KONG_NAMESPACE" 2> /dev/null
    fi
  fi
}

settingKongDB() {
  if [[ "$VKPR_ENV_KONG_MODE" != "dbless" ]]; then
    local PG_HOST="postgres-postgresql.${VKPR_ENV_POSTGRESQL_NAMESPACE}"
    local PG_SECRET="postgres-postgresql"

    if $VKPR_KUBECTL get pod -n "$VKPR_ENV_POSTGRESQL_NAMESPACE" | grep -q pgpool; then
      PG_HOST="postgres-postgresql-pgpool.${VKPR_ENV_POSTGRESQL_NAMESPACE}"
      PG_SECRET="postgres-postgresql-postgresql"
      YQ_VALUES="$YQ_VALUES |
        .env.pg_host = \"$PG_HOST\" |
        .env.pg_password.valueFrom.secretKeyRef.name = \"$PG_SECRET\"
      "
    fi

    if ! $VKPR_KUBECTL get secret -n "$VKPR_ENV_KONG_NAMESPACE" | grep -q "$PG_SECRET"; then
      PG_PASSWORD=$($VKPR_KUBECTL get secret "$PG_SECRET" -o yaml -n "$VKPR_ENV_POSTGRESQL_NAMESPACE" |\
        $VKPR_YQ e ".data.postgresql-password" -)
      $VKPR_KUBECTL create secret generic "$PG_SECRET" --from-literal="postgresql-password=$PG_PASSWORD" -n "$VKPR_ENV_KONG_NAMESPACE" $DRY_RUN_FLAGS
      $VKPR_KUBECTL label secret "$PG_SECRET" vkpr=true app.kubernetes.io/instance=kong -n "$VKPR_ENV_KONG_NAMESPACE" 2> /dev/null
    fi
  fi
}