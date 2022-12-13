#!/usr/bin/env bash

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