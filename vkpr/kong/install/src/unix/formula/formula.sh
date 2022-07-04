#!/bin/bash

source $(dirname "$0")/unix/formula/files.sh

runFormula() {
  local VKPR_KONG_VALUES KONG_NAMESPACE YQ_VALUES HELM_ARGS;
  formulaInputs
  validateInputs

  $VKPR_KUBECTL create ns "$VKPR_ENV_KONG_NAMESPACE" > /dev/null
  
  startInfos
  addKongDependencies
  if [[ $DRY_RUN == false ]]; then
    registerHelmRepository kong https://charts.konghq.com
    createKongSecrets
    installDB
  fi
  settingKong
  installKong
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Kong Install Routine"
  boldNotice "Domain: $VKPR_ENV_GLOBAL_DOMAIN"
  boldNotice "Secure: $VKPR_ENV_GLOBAL_SECURE"
  boldNotice "Namespace: $VKPR_ENV_KONG_NAMESPACE"
  boldNotice "HA: $VKPR_ENV_KONG_HA"
  boldNotice "Deploy Mode: ${VKPR_ENV_KONG_MODE}"
  bold "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "kong.namespace" "KONG_NAMESPACE"
  checkGlobalConfig "$KONG_MODE" "dbless" "kong.mode" "KONG_MODE"
  checkGlobalConfig "$HA" "false" "kong.HA" "KONG_HA"
  checkGlobalConfig "false" "false" "kong.metrics" "KONG_METRICS"
  checkGlobalConfig "false" "false" "kong.vitals.prometheusStrategy" "KONG_VITALS_STRATEGY"
  checkGlobalConfig "$ENTERPRISE" "true" "kong.enterprise.enabled" "KONG_ENTERPRISE"
  checkGlobalConfig "$LICENSE" " " "kong.enterprise.license" "KONG_ENTERPRISE_LICENSE"
  checkGlobalConfig "$RBAC_PASSWORD" "vkpr123" "kong.rbac.adminPassword" "KONG_RBAC_ADMIN_PASSWORD"
  ## Due to a Ritchie variable limitation, we can't deliver those values through vkpr.yaml
  # checkGlobalConfig "$KONG_CP_URL" "kong-kong-cluster.vkpr.svc.cluster.local:8005" "kong.hybrid.dataPlane.controlPlaneEndpoint" "KONG_CP_ENDPOINT"
  # checkGlobalConfig "$KONG_TELEMETRY_URL" "kong-kong-clustertelemetry.vkpr.svc.cluster.local:8006" "kong.hybrid.dataPlane.telemetryEndpoint" "KONG_TELEMETRY_URL"
  # checkGlobalConfig "$KONG_PLANE" "control" "kong.hybrid.plane" "KONG_PLANE"

  # External apps values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "postgresql.namespace" "POSTGRESQL_NAMESPACE"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "PROMETHEUS_STACK_NAMESPACE" 
}

validateInputs() {
  validateKongDomain "$VKPR_ENV_GLOBAL_DOMAIN"
  validateKongSecure "$VKPR_ENV_GLOBAL_SECURE"
  validateKongDeployment "$VKPR_ENV_KONG_MODE"
  validateKongEnterprise "$VKPR_ENV_KONG_ENTERPRISE"
  validateKongHA "$VKPR_ENV_KONG_HA"
  validateKongMetrics "$VKPR_ENV_KONG_METRICS"
  if [[ $VKPR_ENV_KONG_ENTERPRISE = true ]]; then
    validateKongEnterpriseLicensePath "$KONG_ENTERPRISE_LICENSE"
    validateKongRBACPwd "$VKPR_ENV_KONG_RBAC_ADMIN_PASSWORD"
  fi
}

createKongSecrets() {
  info "Creating the Kong Secrets..."

  [[ "$VKPR_ENVIRONMENT" != "okteto" ]] && KONG_NAMESPACE="-n=$VKPR_ENV_KONG_NAMESPACE"

  ## Create license (enable manager)
  LICENSE_CONTENT=${LICENSE:-null}
  $VKPR_KUBECTL create secret generic kong-enterprise-license \
    --from-literal="license=$(cat $LICENSE_CONTENT 2> /dev/null)" $KONG_NAMESPACE && \
    $VKPR_KUBECTL label secret kong-enterprise-license app.kubernetes.io/instance=kong app.kubernetes.io/managed-by=vkpr $KONG_NAMESPACE 2> /dev/null

  if [[ "$VKPR_ENV_KONG_MODE" != "dbless" ]] && [[ "$KONG_PLANE" != "data" ]]; then
    ## Create Kong cookie config
    $VKPR_KUBECTL create secret generic kong-session-config \
      --from-file=/tmp/config/admin_gui_session_conf \
      --from-file=/tmp/config/portal_session_conf $KONG_NAMESPACE && \
    $VKPR_KUBECTL label secret kong-session-config app.kubernetes.io/instance=kong app.kubernetes.io/managed-by=vkpr $KONG_NAMESPACE 2> /dev/null

    ## Create Kong RBAC password
    $VKPR_KUBECTL create secret generic kong-enterprise-superuser-password \
      --from-literal="password=$VKPR_ENV_KONG_RBAC_ADMIN_PASSWORD" $KONG_NAMESPACE && \
     $VKPR_KUBECTL label secret kong-enterprise-superuser-password app.kubernetes.io/instance=kong app.kubernetes.io/managed-by=vkpr $KONG_NAMESPACE 2> /dev/null

    ## Check if exist postgresql password secret in Kong namespace, if not, create one
    if ! $VKPR_KUBECTL get secret $KONG_NAMESPACE | grep -q "$PG_SECRET"; then
      PG_PASSWORD=$($VKPR_KUBECTL get secret "$PG_SECRET" -o=jsonpath="{.data.postgres-password}" -n "$VKPR_ENV_POSTGRESQL_NAMESPACE" | base64 -d -)
      $VKPR_KUBECTL create secret generic "$PG_SECRET" \
        --from-literal="postgres-password=$PG_PASSWORD" $KONG_NAMESPACE && \
        $VKPR_KUBECTL label secret "$PG_SECRET" app.kubernetes.io/instance=kong app.kubernetes.io/managed-by=vkpr $KONG_NAMESPACE 2> /dev/null
    fi
  fi

  ## Create Kong tls secret to communicate between planes
  if [[ "$VKPR_ENV_KONG_MODE" == "hybrid" ]]; then
    $VKPR_KUBECTL create secret tls kong-cluster-cert \
      --cert=$CURRENT_PWD/cluster.crt --key=$CURRENT_PWD/cluster.key $KONG_NAMESPACE && \
      $VKPR_KUBECTL label secret kong-cluster-cert app.kubernetes.io/instance=kong app.kubernetes.io/managed-by=vkpr $KONG_NAMESPACE 2> /dev/null
  fi
}

installDB(){
  if [[ $(checkPodName "$VKPR_ENV_POSTGRESQL_NAMESPACE" "postgres-postgresql") != "true" ]]; then
    info "Initializing postgresql to Kong"
    [[ -f $CURRENT_PWD/vkpr.yaml ]] && cp "$CURRENT_PWD"/vkpr.yaml "$(dirname "$0")"
    rit vkpr postgres install --HA=$VKPR_ENV_KONG_HA --default
  else
    info "Initializing Kong with Postgres already created"
  fi
}

installKong() {
  case $VKPR_ENV_KONG_MODE in
    dbless)
      VKPR_KONG_VALUES="$(dirname "$0")"/utils/kong-dbless.yaml
      ;;
    standard)
      VKPR_KONG_VALUES="$(dirname "$0")"/utils/kong.yaml
      ;;
    hybrid)
      VKPR_KONG_VALUES="$(dirname "$0")"/utils/kong-cp.yaml
      ;;
    esac

  if [[ "$VKPR_ENV_KONG_MODE" = "hybrid" ]] && [[ "$KONG_PLANE" = "data" ]]; then
    VKPR_KONG_VALUES="$(dirname "$0")"/utils/kong-dp.yaml
    installApplication "kong-dp" "kong/kong" "$VKPR_ENV_KONG_NAMESPACE" "$VKPR_KONG_VERSION" "$VKPR_KONG_VALUES" "$HELM_ARGS"
    exit
  fi

  installApplication "kong" "kong/kong" "$VKPR_ENV_KONG_NAMESPACE" "$VKPR_KONG_VERSION" "$VKPR_KONG_VALUES" "$HELM_ARGS"
}

settingKong() {
  YQ_VALUES=".podLabels.[\"app.kubernetes.io/managed-by\"] = \"vkpr\" |
    .enterprise.enabled = true |
    .enterprise.vitals.enabled = true |
    .enterprise.portal.enabled = true
  "

  if [[ "$VKPR_ENV_GLOBAL_DOMAIN" != "localhost" ]]; then
    YQ_VALUES="$YQ_VALUES |
      .admin.ingress.hostname = \"api.manager.$VKPR_ENV_GLOBAL_DOMAIN\" |
      .manager.ingress.hostname = \"manager.$VKPR_ENV_GLOBAL_DOMAIN\" |
      .portal.ingress.hostname = \"portal.$VKPR_ENV_GLOBAL_DOMAIN\" |
      .portalapi.ingress.hostname = \"api.portal.$VKPR_ENV_GLOBAL_DOMAIN\" |
      .env.admin_gui_url = \"https://manager.$VKPR_ENV_GLOBAL_DOMAIN\" |
      .env.admin_api_uri = \"https://api.manager.$VKPR_ENV_GLOBAL_DOMAIN\"|
      .env.portal_gui_host = \"https://portal.$VKPR_ENV_GLOBAL_DOMAIN\" |
      .env.portal_api_url = \"https://api.portal.$VKPR_ENV_GLOBAL_DOMAIN\" |
      .env.portal_gui_protocol = \"https\"
    "
  fi

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .env.portal_gui_protocol = \"https\" |
      .env.admin_gui_url = \"https://manager.$VKPR_ENV_GLOBAL_DOMAIN\" |
      .env.admin_api_uri = \"https://api.manager.$VKPR_ENV_GLOBAL_DOMAIN\" |
      .env.portal_api_url = \"https://api.portal.$VKPR_ENV_GLOBAL_DOMAIN\" |
      .env.portal_gui_host = \"portal.$VKPR_ENV_GLOBAL_DOMAIN\" |
      .admin.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .manager.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .portal.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .portalapi.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .admin.ingress.tls = \"admin-kong-cert\" |
      .manager.ingress.tls = \"manager-kong-cert\" |
      .portal.ingress.tls = \"portal-kong-cert\" |
      .portalapi.ingress.tls = \"portalapi-kong-cert\"
    "
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
    if [[ "$VKPR_ENV_KONG_VITALS_STRATEGY" == "true" ]]; then
      YQ_VALUES="$YQ_VALUES |
        .env.vitals = \"on\" |
        .env.vitals_strategy = \"prometheus\" |
        .env.vitals_statsd_address = \"statsd-kong:9125\" |
        .env.vitals_tsdb_address = \"prometheus-stack-kube-prom-prometheus:9090\" |      
        .env.vitals_statsd_prefix = \"kong-vitals\" 
      "
      $VKPR_KUBECTL apply $KONG_NAMESPACE -f "$(dirname "$0")/utils/kong-service-monitor.yaml"
    fi
  fi

  if [[ "$VKPR_ENV_KONG_HA" == "true" ]]; then
    YQ_VALUES="$YQ_VALUES |
      .autoscaling.enabled = \"true\" |
      .autoscaling.minReplicas = \"3\" |
      .autoscaling.maxReplicas = \"5\" |
      .autoscaling.targetCPUUtilizationPercentage = \"80%\" |
      .topologySpreadConstraints[0].maxSkew = 1 |
      .topologySpreadConstraints[0].topologyKey = \"kubernetes.io/hostname\" |
      .topologySpreadConstraints[0].whenUnsatisfiable = \"DoNotSchedule\" |
      .topologySpreadConstraints[0].labelSelector.matchLabels.vkpr = \"true\" |
      .podDisruptionBudget.enabled = \"true\" |
      .podDisruptionBudget.maxUnavailable = \"60%\" |
      .ingressController.resources.limits.cpu = \"100m\" |
      .ingressController.resources.limits.memory = \"256Mi\" |
      .ingressController.resources.requests.cpu = \"50m\" |
      .ingressController.resources.requests.memory = \"128Mi\" |
      .resources.limits.cpu = \"512m\" |
      .resources.limits.memory = \"1G\" |
      .resources.requests.cpu = \"100m\" |
      .resources.requests.memory = \"128Mi\"
    "
  fi

  if [[ "$VKPR_ENV_KONG_MODE" != "dbless" ]]; then
    local PG_HOST="postgres-postgresql.${VKPR_ENV_POSTGRESQL_NAMESPACE}"
    local PG_SECRET="postgres-postgresql"

    if $VKPR_KUBECTL get pod -n "$VKPR_ENV_POSTGRESQL_NAMESPACE" | grep -q pgpool; then
      PG_HOST="postgres-postgresql-pgpool.${VKPR_ENV_POSTGRESQL_NAMESPACE}"
      PG_SECRET="postgres-postgresql-postgresql"
    fi

    YQ_VALUES="$YQ_VALUES |
      .env.password.valueFrom.secretKeyRef.name = \"kong-enterprise-superuser-password\" |
      .env.password.valueFrom.secretKeyRef.key = \"password\" |
      .ingressController.env.kong_admin_token.valueFrom.secretKeyRef.name = \"kong-enterprise-superuser-password\" |
      .ingressController.env.kong_admin_token.valueFrom.secretKeyRef.key = \"password\" |
      .enterprise.rbac.enabled = true |
      .enterprise.rbac.admin_gui_auth = \"basic-auth\" |
      .enterprise.rbac.session_conf_secret = \"kong-session-config\" |
      .env.enforce_rbac = \"on\" |
      .env.enforce_rbac style=\"double\" |
      .env.pg_host = \"$PG_HOST\" |
      .env.pg_password.valueFrom.secretKeyRef.name = \"$PG_SECRET\"
    "
  fi

  if [[ "$VKPR_ENV_KONG_MODE" = "hybrid" ]]; then
    if [[ "$KONG_PLANE" = "data" ]]; then
      YQ_VALUES=".env.cluster_control_plane = \"$KONG_CP_URL\" |
        .env.cluster_telemetry_endpoint = \"$KONG_TELEMETRY_URL\"
      "
    else
      YQ_VALUES="$YQ_VALUES |
        .proxy.enabled = false
      "
    fi
  fi

  settingKongProvider

  debug "YQ_CONTENT = $YQ_VALUES"
}

settingKongProvider(){
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    OKTETO_NAMESPACE=$($VKPR_KUBECTL config get-contexts --no-headers | grep "\*" | xargs | awk -F " " '{print $NF}')
    HELM_ARGS="--skip-crds"
    YQ_VALUES="$YQ_VALUES |
        del(.portal.ingress) |
        del(.admin.ingress) |
        del(.portalapi.ingress) |
        del(.manager.ingress) |                       
        del(.ingressController) |
        .ingressController.enabled = false |
        .ingressController.installCRDs = false |
        .admin.ingress.enabled = false |
        .manager.ingress.enabled = false |
        .portal.ingress.enabled = false |
        .portalapi.ingress.enabled = false |
        .proxy.tls.enabled = false |
        .admin.annotations.[\"dev.okteto.com/auto-ingress\"] = \"true\" |
        .manager.annotations.[\"dev.okteto.com/auto-ingress\"] = \"true\" |
        .portal.annotations.[\"dev.okteto.com/auto-ingress\"] = \"true\" |
        .portalapi.annotations.[\"dev.okteto.com/auto-ingress\"] = \"true\" |
        .proxy.annotations.[\"dev.okteto.com/auto-ingress\"] = \"true\" |
        .proxy.type = \"ClusterIP\" |
        .env.admin_gui_url = \"https://kong-kong-manager-$OKTETO_NAMESPACE.cloud.okteto.net\" |
        .env.admin_api_uri = \"https://kong-kong-admin-$OKTETO_NAMESPACE.cloud.okteto.net\" |
        .env.portal_gui_host = \"kong-kong-portal-$OKTETO_NAMESPACE.cloud.okteto.net\" |
        .env.proxy_url = \"https://kong-kong-proxy-$OKTETO_NAMESPACE.cloud.okteto.net\" |
        .env.portal_api_url = \"https://kong-kong-portalapi-$OKTETO_NAMESPACE.cloud.okteto.net\" | 
        .env.portal_gui_protocol = \"https\" |
        .env.pg_host = \"postgres-postgresql\" |
        .env.pg_password.valueFrom.secretKeyRef.key = \"postgres-password\" 
      "
  fi  
}
