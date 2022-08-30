#!/usr/bin/env bash

runFormula() {
  local VKPR_KONG_VALUES KONG_NAMESPACE YQ_VALUES HELM_ARGS;
  formulaInputs
  validateInputs

  [[ "$VKPR_ENVIRONMENT" != "okteto" ]] && $VKPR_KUBECTL create ns "$VKPR_ENV_KONG_NAMESPACE" > /dev/null

  startInfos
  if [[ $DRY_RUN == false ]]; then
    registerHelmRepository kong https://charts.konghq.com
    createKongSecrets
  fi
  settingKong
  installKong
  [[ $DRY_RUN == false ]] && [[ "$VKPR_ENVIRONMENT" != "okteto" ]] && installPlugins || true
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
  checkGlobalConfig "$MODE" "dbless" "kong.mode" "KONG_MODE"
  checkGlobalConfig "$HA" "false" "kong.HA" "KONG_HA"
  checkGlobalConfig "false" "false" "kong.metrics" "KONG_METRICS"
  checkGlobalConfig "false" "false" "kong.vitals.prometheusStrategy" "KONG_VITALS_STRATEGY"
  checkGlobalConfig "${LICENSE:-null}" "null" "kong.enterprise.license" "KONG_ENTERPRISE_LICENSE"
  checkGlobalConfig "${RBAC_PASSWORD:-"vkpr123"}" "vkpr123" "kong.rbac.adminPassword" "KONG_RBAC_ADMIN_PASSWORD"
  checkGlobalConfig "${CP_URL:-"kong-kong-cluster.vkpr.svc.cluster.local:8005"}" "kong-kong-cluster.vkpr.svc.cluster.local:8005" \
    "kong.hybrid.dataPlane.controlPlaneEndpoint" "KONG_CP_ENDPOINT"
  checkGlobalConfig "${TELEMETRY_URL:-"kong-kong-clustertelemetry.vkpr.svc.cluster.local:8006"}" "kong-kong-clustertelemetry.vkpr.svc.cluster.local:8006" \
    "kong.hybrid.dataPlane.telemetryEndpoint" "KONG_TELEMETRY_URL"
  checkGlobalConfig "${PLANE:-control}" "control" "kong.hybrid.plane" "KONG_PLANE"

  # Integrate
  checkGlobalConfig "false" "false" "kong.rbac.openid.enabled" "KONG_KEYCLOAK_OPENID"
  checkGlobalConfig "" "" "kong.rbac.openid.clientSecret" "KONG_KEYCLOAK_OPENID_CLIENTSECRET"

  # External apps values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "postgresql.namespace" "POSTGRESQL_NAMESPACE"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "GRAFANA_NAMESPACE"
}

validateInputs() {
  validateKongDomain "$VKPR_ENV_GLOBAL_DOMAIN"
  validateKongSecure "$VKPR_ENV_GLOBAL_SECURE"
  validateKongDeployment "$VKPR_ENV_KONG_MODE"
  validateKongHA "$VKPR_ENV_KONG_HA"
  validateKongMetrics "$VKPR_ENV_KONG_METRICS"
  validateKongRBACPwd "$VKPR_ENV_KONG_RBAC_ADMIN_PASSWORD"
}

createKongSecrets() {
  info "Creating the Kong Secrets..."

  [[ "$VKPR_ENVIRONMENT" != "okteto" ]] && KONG_NAMESPACE="-n=$VKPR_ENV_KONG_NAMESPACE"

  ## Create license (enable manager)
  $VKPR_KUBECTL create secret generic kong-enterprise-license \
    --from-literal="license=$(cat $VKPR_ENV_KONG_ENTERPRISE_LICENSE 2> /dev/null)" $KONG_NAMESPACE && \
    $VKPR_KUBECTL label secret kong-enterprise-license app.kubernetes.io/instance=kong app.kubernetes.io/managed-by=vkpr $KONG_NAMESPACE 2> /dev/null
}

installDB(){
  if [[ $(checkPodName "$VKPR_ENV_POSTGRESQL_NAMESPACE" "postgres-postgresql") != "true" ]]; then
    info "Initializing postgresql to Kong"
    [[ -f $CURRENT_PWD/vkpr.yaml ]] && cp "$CURRENT_PWD"/vkpr.yaml "$(dirname "$0")"
    rit vkpr postgresql install --HA=$VKPR_ENV_KONG_HA --default
  else
    info "Initializing Kong with Postgres already created"
  fi
}

settingKong() {
  case $VKPR_ENV_KONG_MODE in
    dbless)
      source "$(dirname "$0")"/unix/formula/kong-dbless.sh
      VKPR_KONG_VALUES="$(dirname "$0")"/utils/kong-dbless.yaml
      ;;
    standard)
      source "$(dirname "$0")"/unix/formula/kong-standard.sh
      VKPR_KONG_VALUES="$(dirname "$0")"/utils/kong.yaml
      ;;
    hybrid)
      if [[ "$KONG_PLANE" == "data" ]]; then
        source "$(dirname "$0")"/unix/formula/kong-dp.sh
        VKPR_KONG_VALUES="$(dirname "$0")"/utils/kong-dp.yaml
      else
        source "$(dirname "$0")"/unix/formula/kong-cp.sh
        VKPR_KONG_VALUES="$(dirname "$0")"/utils/kong-cp.yaml
      fi
      ;;
    esac
}

installKong() {
  if [[ "$VKPR_ENV_KONG_MODE" == "hybrid" ]] && [[ "$KONG_PLANE" == "data" ]]; then
    installApplication "kong-dp" "kong/kong" "$VKPR_ENV_KONG_NAMESPACE" "$VKPR_KONG_VERSION" "$VKPR_KONG_VALUES" "$HELM_ARGS"
    exit
  fi

  installApplication "kong" "kong/kong" "$VKPR_ENV_KONG_NAMESPACE" "$VKPR_KONG_VERSION" "$VKPR_KONG_VALUES" "$HELM_ARGS"
}

installPlugins() {
  if [[ "$VKPR_ENV_KONG_MODE" == "dbless" ]]; then
    $VKPR_KUBECTL apply -n $VKPR_ENV_KONG_NAMESPACE -f "$(dirname "$0")"/utils/kong-plugin-basicauth.yaml
  fi
}
