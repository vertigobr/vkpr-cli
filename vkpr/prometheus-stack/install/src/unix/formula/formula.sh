#!/bin/bash

runFormula() {
  checkGlobalConfig "$DOMAIN" "localhost" "domain" "DOMAIN"
  checkGlobalConfig "$SECURE" "false" "secure" "SECURE"
  checkGlobalConfig "$ALERTMANAGER" "false" "prometheus-stack.alertManager.enabled" "PROMETHEUS_ALERT_MANAGER"
  checkGlobalConfig "$HA" "false" "prometheus-stack.alertmanager.HA" "PROMETHEUS_ALERT_MANAGER_HA"
  checkGlobalConfig "$GRAFANA_PASSWORD" "vkpr123" "prometheus-stack.grafana.adminPassword" "GRAFANA_PASSWORD"
  checkGlobalConfig "nginx" "nginx" "prometheus-stack.ingressClassName" "PROMETHEUS_INGRESS"
  checkGlobalConfig "true" "true" "prometheus-stack.grafana.k8sExporters" "PROMETHEUS_STACK_K8S_EXPORTERS"
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "prometheus-stack.namespace" "PROMETHEUS_STACK_NAMESPACE"
  
  # External app values
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "loki.namespace" "LOKI_NAMESPACE"

  local VKPR_ENV_GRAFANA_DOMAIN="grafana.${VKPR_ENV_DOMAIN}" \
    VKPR_ENV_ALERT_MANAGER_DOMAIN="alertmanager.${VKPR_ENV_DOMAIN}"

  local VKPR_PROMETHEUS_VALUES; VKPR_PROMETHEUS_VALUES=$(dirname "$0")/utils/prometheus-stack.yaml
  
  startInfos
  addRepoPrometheusStack
  installPrometheusStack
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Prometheus-Stack Install Routine")"
  echoColor "bold" "$(echoColor "blue" "Grafana domain:") ${VKPR_ENV_GRAFANA_DOMAIN}"
  echoColor "bold" "$(echoColor "blue" "Grafana password:") ${VKPR_ENV_GRAFANA_PASSWORD}"
  echoColor "bold" "$(echoColor "blue" "Prometheus AlertManager enabled:") ${VKPR_ENV_PROMETHEUS_ALERT_MANAGER}"
  [[ $VKPR_ENV_PROMETHEUS_ALERT_MANAGER == true ]] && echoColor "bold" "$(echoColor "blue" "Prometheus AlertManager domain:") ${VKPR_ENV_ALERT_MANAGER_DOMAIN}"
  echoColor "bold" "$(echoColor "blue" "Ingress Controller:") ${VKPR_ENV_PROMETHEUS_INGRESS}"
  echo "=============================="
}

addRepoPrometheusStack() {
  registerHelmRepository prometheus-community https://prometheus-community.github.io/helm-charts
}

installPrometheusStack() {
  echoColor "bold" "$(echoColor "green" "Installing prometheus-stack...")"
  local YQ_VALUES=".grafana.ingress.hosts[0] = \"$VKPR_ENV_GRAFANA_DOMAIN\" | .grafana.adminPassword = \"$VKPR_ENV_GRAFANA_PASSWORD\""
  settingStack

  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_PROMETHEUS_VALUES" \
  | $VKPR_HELM upgrade -i --version "$VKPR_PROMETHEUS_STACK_VERSION" \
    --namespace "$VKPR_ENV_PROMETHEUS_STACK_NAMESPACE" --create-namespace \
    --wait -f - prometheus-stack prometheus-community/kube-prometheus-stack
}

settingStack() {
  if [[ "$VKPR_ENV_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .grafana.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .grafana.ingress.tls[0].hosts[0] = \"$VKPR_ENV_GRAFANA_DOMAIN\" |
      .grafana.ingress.tls[0].secretName = \"grafana-cert\"
    "

    if [[ "$VKPR_ENV_PROMETHEUS_ALERT_MANAGER" == true ]]; then
      YQ_VALUES="$YQ_VALUES |
        .alertmanager.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
        .alertmanager.ingress.tls[0].hosts[0] = \"$VKPR_ENV_ALERT_MANAGER_DOMAIN\" |
        .alertmanager.ingress.tls[0].secretName = \"alertmanager-cert\"
      "
    fi
  fi

  if [[ "$VKPR_ENV_PROMETHEUS_ALERT_MANAGER" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .alertmanager.enabled = true |
      .alertmanager.ingress.enabled = true |
      .alertmanager.ingress.hosts[0] = \"$VKPR_ENV_ALERT_MANAGER_DOMAIN\"
    "

    if [[ "$PROMETHEUS_ALERT_MANAGER_HA" == true ]]; then
      YQ_VALUES="$YQ_VALUES |
        .alertmanager.alertmanagerSpec.replicas = 3 |
        .prometheus.prometheusSpec.replicas = 3
      "
    fi
  fi

  if [[ "$VKPR_ENV_PROMETHEUS_INGRESS" != "nginx" ]]; then
    YQ_VALUES="$YQ_VALUES |
      .alertmanager.ingress.ingressClassName = \"$VKPR_ENV_PROMETHEUS_INGRESS\" |
      .grafana.ingress.ingressClassName = \"$VKPR_ENV_PROMETHEUS_INGRESS\"
    "
  fi

  if [[ "$VKPR_ENV_PROMETHEUS_STACK_K8S_EXPORTERS" == true ]]; then
    YQ_VALUES="$YQ_VALUES |      
      .kubeApiServer.enabled = true |
      .kubelet.enabled = true |
      .kubeControllerManager.enabled = true |
      .coreDns.enabled = true |
      .kubeDns.enabled = false |
      .kubeEtcd.enabled = true |
      .kubeScheduler.enabled = true |
      .kubeProxy.enabled = true |
      .kubeStateMetrics.enabled = true |
      .nodeExporter.enabled = true
    "
  fi

  if [[ $(checkPodName "$VKPR_ENV_LOKI_NAMESPACE" "loki-stack") == "true" ]]; then
    YQ_VALUES="$YQ_VALUES |
      .grafana.additionalDataSources[0].name = \"Loki\" |
      .grafana.additionalDataSources[0].type = \"loki\" |
      .grafana.additionalDataSources[0].url = \"http://loki-stack.$VKPR_ENV_LOKI_NAMESPACE:3100\" |
      .grafana.additionalDataSources[0].access = \"proxy\" |
      .grafana.additionalDataSources[0].basicAuth = false |
      .grafana.additionalDataSources[0].editable = true
    "
  fi

  mergeVkprValuesHelmArgs "prometheus-stack" "$VKPR_PROMETHEUS_VALUES"
}