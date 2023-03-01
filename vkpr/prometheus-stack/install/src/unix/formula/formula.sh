#!/usr/bin/env bash

runFormula() {
  local VKPR_ENV_GRAFANA_DOMAIN VKPR_ENV_ALERT_MANAGER_DOMAIN VKPR_PROMETHEUS_VALUES HELM_ARGS;
  formulaInputs
  validateInputs

  VKPR_ENV_GRAFANA_DOMAIN="grafana.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_ENV_ALERT_MANAGER_DOMAIN="alertmanager.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_ENV_PROMETHEUS_DOMAIN="prometheus.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_PROMETHEUS_VALUES=$(dirname "$0")/utils/prometheus-stack.yaml
  VKPR_LOKI_DASHBOARD=$(dirname "$0")/utils/loki-dashboard.json

  startInfos
  settingPrometheusStack
  [ $DRY_RUN = false ] && registerHelmRepository prometheus-community https://prometheus-community.github.io/helm-charts
  installApplication "prometheus-stack" "prometheus-community/kube-prometheus-stack" "$VKPR_ENV_PROMETHEUS_STACK_NAMESPACE" "$VKPR_PROMETHEUS_STACK_VERSION" "$VKPR_PROMETHEUS_VALUES" "$HELM_ARGS"
  $VKPR_KUBECTL label secret/prometheus-stack-kube-prom-admission app.kubernetes.io/managed-by=vkpr -n $VKPR_ENV_PROMETHEUS_STACK_NAMESPACE
  importDashboard "$VKPR_LOKI_DASHBOARD" "$VKPR_ENV_PROMETHEUS_STACK_NAMESPACE"
  [ $DRY_RUN = false ] && checkComands
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Prometheus-Stack Install Routine"
  boldNotice "Domain: $VKPR_ENV_GLOBAL_DOMAIN"
  boldNotice "Secure: $VKPR_ENV_GLOBAL_SECURE"
  boldNotice "Ingress Controller: $VKPR_ENV_PROMETHEUS_STACK_INGRESS_CLASS_NAME"
  boldNotice "Grafana password: $VKPR_ENV_GRAFANA_PASSWORD"
  boldNotice "AlertManager enabled: $VKPR_ENV_ALERTMANAGER"
  bold "=============================="
}

checkComands (){
  COMANDS_EXISTS=$($VKPR_YQ eval ".prometheus-stack | has(\"commands\")" "$VKPR_FILE" 2> /dev/null)
  debug "$COMANDS_EXISTS"
  if [ "$COMANDS_EXISTS" == true ]; then
    bold "=============================="
    boldInfo "Checking additional prometheus-stack commands..."
    if [ $($VKPR_YQ eval ".prometheus-stack.commands | has(\"import\")" "$VKPR_FILE") == true ]; then
      checkGlobalConfig "" "" "prometheus-stack.commands.import" "DASHBOARD_PATH"
      validatePrometheusImportDashboardPath "$VKPR_ENV_DASHBOARD_PATH"
      importDashboard "$VKPR_ENV_DASHBOARD_PATH" "$VKPR_ENV_PROMETHEUS_STACK_NAMESPACE"
    fi
  fi
}