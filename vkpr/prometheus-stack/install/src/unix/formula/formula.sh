#!/bin/bash

runFormula() {
  # Global values
  checkGlobalConfig "$DOMAIN" "localhost" "global.domain" "GLOBAL_DOMAIN"
  checkGlobalConfig "$SECURE" "false" "global.secure" "GLOBAL_SECURE"
  checkGlobalConfig "nginx" "nginx" "global.ingressClassName" "GLOBAL_INGRESS"
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "global.namespace" "GLOBAL_NAMESPACE"
  
  # App values
  checkGlobalConfig "$ALERTMANAGER" "false" "prometheus-stack.alertManager.enabled" "PROMETHEUS_ALERT_MANAGER"
  checkGlobalConfig "$HA" "false" "prometheus-stack.alertManager.HA" "PROMETHEUS_ALERT_MANAGER_HA"
  checkGlobalConfig "$GRAFANA_PASSWORD" "vkpr123" "prometheus-stack.grafana.adminPassword" "GRAFANA_PASSWORD"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS" "$VKPR_ENV_GLOBAL_INGRESS" "prometheus-stack.ingressClassName" "PROMETHEUS_INGRESS"
  checkGlobalConfig "true" "true" "prometheus-stack.grafana.k8sExporters" "PROMETHEUS_STACK_K8S_EXPORTERS"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "PROMETHEUS_STACK_NAMESPACE"
  checkGlobalConfig "false" "false" "prometheus-stack.grafana.persistance" "GRAFANA_PERSISTANCE"
  checkGlobalConfig "false" "false" "prometheus-stack.prometheus.persistance" "PROMETHEUS_PERSISTANCE"
  
  # External app values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "loki.namespace" "LOKI_NAMESPACE"

  local VKPR_ENV_GRAFANA_DOMAIN="grafana.${VKPR_ENV_GLOBAL_DOMAIN}" \
    VKPR_ENV_ALERT_MANAGER_DOMAIN="alertmanager.${VKPR_ENV_GLOBAL_DOMAIN}"

  local VKPR_PROMETHEUS_VALUES; VKPR_PROMETHEUS_VALUES=$(dirname "$0")/utils/prometheus-stack.yaml
  
  startInfos
  addRepoPrometheusStack
  installPrometheusStack
}

startInfos() {
  echo "=============================="
  info "VKPR Prometheus-Stack Install Routine"
  notice "Grafana domain: $VKPR_ENV_GRAFANA_DOMAIN"
  notice "Grafana password: $VKPR_ENV_GRAFANA_PASSWORD"
  notice "Prometheus AlertManager enabled: $VKPR_ENV_PROMETHEUS_ALERT_MANAGER"
  [[ $VKPR_ENV_PROMETHEUS_ALERT_MANAGER == true ]] && notice "Prometheus AlertManager domain: $VKPR_ENV_ALERT_MANAGER_DOMAIN"
  notice "Ingress Controller: $VKPR_ENV_PROMETHEUS_INGRESS"
  echo "=============================="
}

addRepoPrometheusStack() {
  registerHelmRepository prometheus-community https://prometheus-community.github.io/helm-charts
}

installPrometheusStack() {
  local YQ_VALUES=".grafana.ingress.hosts[0] = \"$VKPR_ENV_GRAFANA_DOMAIN\" | .grafana.adminPassword = \"$VKPR_ENV_GRAFANA_PASSWORD\""
  settingStack

  if [[ $DRY_RUN == true ]]; then
    echo "---"
    $VKPR_YQ eval "$YQ_VALUES" "$VKPR_PROMETHEUS_VALUES"
    mergeVkprValuesHelmArgs "prometheus-stack" "$VKPR_PROMETHEUS_VALUES"    
  else
    info "Installing prometheus-stack..."
    $VKPR_YQ eval -i "$YQ_VALUES" "$VKPR_PROMETHEUS_VALUES"
    mergeVkprValuesHelmArgs "prometheus-stack" "$VKPR_PROMETHEUS_VALUES"
    $VKPR_HELM upgrade -i --version "$VKPR_PROMETHEUS_STACK_VERSION" \
      --namespace "$VKPR_ENV_PROMETHEUS_STACK_NAMESPACE" --create-namespace \
      --wait -f "$VKPR_PROMETHEUS_VALUES" prometheus-stack prometheus-community/kube-prometheus-stack
  fi
}

settingStack() {
  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
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

  if [[ "$VKPR_ENV_GRAFANA_PERSISTANCE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .grafana.persistence.enabled = true |
      .grafana.persistence.size = \"8Gi\"
    "
  fi

  if [[ "$VKPR_ENV_PROMETHEUS_PERSISTANCE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0] = \"ReadWriteOnce\" |
      .prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage = \"8Gi\"
    "
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
}
