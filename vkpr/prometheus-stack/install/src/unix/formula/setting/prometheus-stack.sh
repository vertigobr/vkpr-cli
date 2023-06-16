#!/usr/bin/env bash

settingPrometheusStack() {
  [ $DRY_RUN = false ] && installLokiDatasource
  settingGrafanaValues
  settingPrometheusValues
  [[ "$VKPR_ENV_ALERTMANAGER" == true ]] && settingAlertManagerValues


  if [[ "$VKPR_ENV_PROMETHEUS_STACK_EXPORTERS" == true ]]; then
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

  if [[ $(checkPodName "$VKPR_ENV_LOKI_NAMESPACE" "loki") == "true" ]]; then
    YQ_VALUES="$YQ_VALUES |
      .grafana.additionalDataSources[0].name = \"Loki\" |
      .grafana.additionalDataSources[0].type = \"loki\" |
      .grafana.additionalDataSources[0].url = \"http://loki.$VKPR_ENV_PROMETHEUS_STACK_NAMESPACE:3100\" |
      .grafana.additionalDataSources[0].access = \"proxy\" |
      .grafana.additionalDataSources[0].basicAuth = false |
      .grafana.additionalDataSources[0].editable = true
    "
  fi

  if [[ "$VKPR_ENV_PROMETHEUS_STACK_HA" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .alertmanager.alertmanagerSpec.replicas = 3 |
      .alertmanager.alertmanagerSpec.retention = \"1d\" |
      .prometheus.prometheusSpec.replicas = 3 |
      .prometheus.prometheusSpec.retention = \"90d\"
    "
  fi

  settingPrometheusStackEnvironment

  debug "YQ_CONTENT = $YQ_VALUES"
}

settingPrometheusStackEnvironment() {
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    # YQ_VALUES="$YQ_VALUES"
  fi
}

installLokiDatasource(){
  if [[ $(checkPodName "$VKPR_ENV_PROMETHEUS_STACK_NAMESPACE" "loki-0") != "true" ]]; then
    info "Initializing Loki to Prometheus-stack"
    [[ -f $CURRENT_PWD/vkpr.yaml ]] && cp "$CURRENT_PWD"/vkpr.yaml "$(dirname "$0")"
    rit vkpr loki install --default
  else
    info "Initializing Prometheus-stack with Loki already created"
  fi
}
