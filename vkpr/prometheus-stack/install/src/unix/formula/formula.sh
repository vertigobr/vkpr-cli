#!/usr/bin/env bash

runFormula() {
  local VKPR_ENV_GRAFANA_DOMAIN VKPR_ENV_ALERT_MANAGER_DOMAIN VKPR_PROMETHEUS_VALUES HELM_ARGS;
  formulaInputs
  validateInputs

  VKPR_ENV_GRAFANA_DOMAIN="grafana.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_ENV_ALERT_MANAGER_DOMAIN="alertmanager.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_ENV_PROMETHEUS_DOMAIN="prometheus.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_PROMETHEUS_VALUES=$(dirname "$0")/utils/prometheus-stack.yaml

  startInfos
  settingPrometheusStack
  [ $DRY_RUN = false ] && registerHelmRepository prometheus-community https://prometheus-community.github.io/helm-charts
  installApplication "prometheus-stack" "prometheus-community/kube-prometheus-stack" "$VKPR_ENV_PROMETHEUS_STACK_NAMESPACE" "$VKPR_PROMETHEUS_STACK_VERSION" "$VKPR_PROMETHEUS_VALUES" "$HELM_ARGS"
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

formulaInputs() {
  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "prometheus-stack.ingressClassName" "PROMETHEUS_STACK_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "PROMETHEUS_STACK_NAMESPACE"
  ## AlertManager
  checkGlobalConfig "$ALERTMANAGER" "false" "prometheus-stack.alertManager.enabled" "ALERTMANAGER"
  if [[ "$VKPR_ENV_ALERTMANAGER" = true ]]; then
    checkGlobalConfig "$HA" "false" "prometheus-stack.alertManager.HA" "ALERTMANAGER_HA"
    checkGlobalConfig "false" "false" "prometheus-stack.alertManager.ssl.enabled" "ALERTMANAGER_SSL"
    checkGlobalConfig "" "" "prometheus-stack.alertManager.ssl.crt" "ALERTMANAGER_CERTIFICATE"
    checkGlobalConfig "" "" "prometheus-stack.alertManager.ssl.key" "ALERTMANAGER_KEY"
    checkGlobalConfig "" "" "prometheus-stack.alertManager.ssl.secretName" "ALERTMANAGER_SSL_SECRET"
  fi
  ## Grafana
  checkGlobalConfig "$GRAFANA_PASSWORD" "vkpr123" "prometheus-stack.grafana.adminPassword" "GRAFANA_PASSWORD"
  checkGlobalConfig "false" "false" "prometheus-stack.grafana.k8sExporters" "PROMETHEUS_STACK_K8S_EXPORTERS"
  checkGlobalConfig "false" "false" "prometheus-stack.grafana.persistance" "GRAFANA_PERSISTANCE"
  checkGlobalConfig "$SSL" "false" "prometheus-stack.grafana.ssl.enabled" "GRAFANA_SSL"
  if [[ "$VKPR_ENV_GRAFANA_SSL" = true ]]; then
    checkGlobalConfig "$CRT_FILE" "" "prometheus-stack.grafana.ssl.crt" "GRAFANA_CERTIFICATE"
    checkGlobalConfig "$KEY_FILE" "" "prometheus-stack.grafana.ssl.key" "GRAFANA_KEY"
    checkGlobalConfig "" "" "prometheus-stack.grafana.ssl.secretName" "GRAFANA_SSL_SECRET"
  fi
  ## Prometheus
  checkGlobalConfig "false" "false" "prometheus-stack.prometheus.enabled" "PROMETHEUS"
  if [[ "$VKPR_ENV_PROMETHEUS" = true ]]; then
    checkGlobalConfig "false" "false" "prometheus-stack.prometheus.ssl.enabled" "PROMETHEUS_SSL"
    checkGlobalConfig "" "" "prometheus-stack.prometheus.ssl.crt" "PROMETHEUS_CERTIFICATE"
    checkGlobalConfig "" "" "prometheus-stack.prometheus.ssl.key" "PROMETHEUS_KEY"
    checkGlobalConfig "" "" "prometheus-stack.prometheus.ssl.secretName" "PROMETHEUS_SSL_SECRET"
  fi
  checkGlobalConfig "false" "false" "prometheus-stack.prometheus.persistance" "PROMETHEUS_PERSISTANCE"


  # External app values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "loki.namespace" "LOKI_NAMESPACE"
}

validateInputs() {
  # App values
  validatePrometheusDomain "$VKPR_ENV_GLOBAL_DOMAIN"
  validatePrometheusSecure "$VKPR_ENV_GLOBAL_SECURE"
  validatePrometheusIngressClassName "$VKPR_ENV_PROMETHEUS_STACK_INGRESS_CLASS_NAME"
  validatePrometheusNamespace "$VKPR_ENV_PROMETHEUS_STACK_NAMESPACE"
  ## AlertManager
  validateAlertManagerEnabled "$VKPR_ENV_ALERTMANAGER"
  if [[ "$VKPR_ENV_ALERTMANAGER" = true ]]; then
    validateAlertManagerHA "$VKPR_ENV_ALERTMANAGER_HA"
    validateAlertManagerSSL "$VKPR_ENV_ALERTMANAGER_SSL"
    if [[ "$VKPR_ENV_ALERTMANAGER_SSL" = true ]]; then
      validateAlertManagerCertificate "$VKPR_ENV_ALERTMANAGER_CERTIFICATE"
      validateAlertManagerKey "$VKPR_ENV_ALERTMANAGER_KEY"
      validateAlertManagerSecret "$VKPR_ENV_ALERTMANAGER_SSL_SECRET"
    fi
  fi
  ## Grafana
  validateGrafanaPwd "$VKPR_ENV_GRAFANA_PASSWORD"
  validatePrometheusK8S "$VKPR_ENV_PROMETHEUS_STACK_K8S_EXPORTERS"
  validateGrafanaPersistance "$VKPR_ENV_GRAFANA_PERSISTANCE"
  validateGrafanaSSL "$VKPR_ENV_GRAFANA_SSL"
  if [[ "$VKPR_ENV_GRAFANA_SSL" = true ]]; then
    validateGrafanaCertificate "$VKPR_ENV_GRAFANA_CERTIFICATE"
    validateGrafanaKey "$VKPR_ENV_GRAFANA_KEY"
    validateGrafanaSecret "$VKPR_ENV_GRAFANA_SSL_SECRET"
  fi
  ## Prometheus
  validatePrometheusEnabled "$VKPR_ENV_PROMETHEUS"
  if [[ "$VKPR_ENV_PROMETHEUS" = true ]]; then
    validatePrometheusSSL "$VKPR_ENV_PROMETHEUS_SSL"
    if [[ "$VKPR_ENV_PROMETHEUS_SSL" = true ]]; then
      validatePrometheusCertificate "$VKPR_ENV_PROMETHEUS_CERTIFICATE"
      validatePrometheusKey "$VKPR_ENV_PROMETHEUS_KEY"
      validatePrometheusSecret "$VKPR_ENV_PROMETHEUS_SSL_SECRET"
    fi
  fi
  validatePrometheusPersistance "$VKPR_ENV_PROMETHEUS_PERSISTANCE"
  # External app values
  validateLokiNamespace "$VKPR_ENV_LOKI_NAMESPACE"
}

settingPrometheusStack() {
  settingGrafanaValues
  settingPrometheusValues
  [[ "$VKPR_ENV_ALERTMANAGER" == true ]] && settingAlertManagerValues

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

  settingPrometheusStackEnvironment

  debug "YQ_CONTENT = $YQ_VALUES"
}

settingGrafanaValues() {
  YQ_VALUES=".grafana.ingress.hosts[0] = \"$VKPR_ENV_GRAFANA_DOMAIN\" |
   .grafana.adminPassword = \"$VKPR_ENV_GRAFANA_PASSWORD\" |
   .grafana.ingress.ingressClassName = \"$VKPR_ENV_PROMETHEUS_STACK_INGRESS_CLASS_NAME\"
  "

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .grafana.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .grafana.ingress.tls[0].hosts[0] = \"$VKPR_ENV_GRAFANA_DOMAIN\" |
      .grafana.ingress.tls[0].secretName = \"grafana-cert\"
    "
  fi

  if [[ "$VKPR_ENV_GRAFANA_SSL" == "true" ]]; then
    if [[ "$VKPR_ENV_GRAFANA_SSL_SECRET" == "" ]]; then
      VKPR_ENV_GRAFANA_SSL_SECRET="grafana-certificate"
      $VKPR_KUBECTL create secret tls $VKPR_ENV_GRAFANA_SSL_SECRET -n "$VKPR_ENV_GRAFANA_NAMESPACE" \
        --cert="$VKPR_ENV_GRAFANA_CERTIFICATE" \
        --key="$VKPR_ENV_GRAFANA_KEY"
    fi
    YQ_VALUES="$YQ_VALUES |
      .grafana.ingress.tls[0].hosts[0] = \"$VKPR_ENV_GRAFANA_DOMAIN\" |
      .grafana.ingress.tls[0].secretName = \"$VKPR_ENV_GRAFANA_SSL_SECRET\"
     "
  fi

  if [[ "$VKPR_ENV_GRAFANA_PERSISTANCE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .grafana.persistence.enabled = true |
      .grafana.persistence.size = \"8Gi\"
    "
  fi
}

settingPrometheusValues() {
  YQ_VALUES="$YQ_VALUES |
    .prometheus.enabled = true |
    .prometheus.ingress.enabled = true |
    .prometheus.ingress.hosts[0] = \"$VKPR_ENV_PROMETHEUS_DOMAIN\" |
    .prometheus.ingress.ingressClassName = \"$VKPR_ENV_PROMETHEUS_STACK_INGRESS_CLASS_NAME\"
  "

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .prometheus.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .prometheus.ingress.tls[0].hosts[0] = \"$VKPR_ENV_PROMETHEUS_DOMAIN\" |
      .prometheus.ingress.tls[0].secretName = \"prometheus-cert\"
    "
  fi

  if [[ "$VKPR_ENV_PROMETHEUS_SSL" == "true" ]]; then
    if [[ "$VKPR_ENV_PROMETHEUS_SSL_SECRET" == "" ]]; then
      VKPR_ENV_PROMETHEUS_SSL_SECRET="prometheus-certificate"
      $VKPR_KUBECTL create secret tls $VKPR_ENV_PROMETHEUS_SSL_SECRET -n "$VKPR_ENV_PROMETHEUS_NAMESPACE" \
        --cert="$VKPR_ENV_PROMETHEUS_CERTIFICATE" \
        --key="$VKPR_ENV_PROMETHEUS_KEY"
    fi
    YQ_VALUES="$YQ_VALUES |
      .prometheus.ingress.tls[0].hosts[0] = \"$VKPR_ENV_PROMETHEUS_DOMAIN\" |
      .prometheus.ingress.tls[0].secretName = \"$VKPR_ENV_PROMETHEUS_SSL_SECRET\"
     "
  fi

  if [[ "$VKPR_ENV_PROMETHEUS_PERSISTANCE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0] = \"ReadWriteOnce\" |
      .prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage = \"8Gi\"
    "
  fi
}

settingAlertManagerValues() {
  YQ_VALUES="$YQ_VALUES |
    .alertmanager.enabled = true |
    .alertmanager.ingress.enabled = true |
    .alertmanager.ingress.hosts[0] = \"$VKPR_ENV_ALERT_MANAGER_DOMAIN\" |
    .alertmanager.ingress.ingressClassName = \"$VKPR_ENV_PROMETHEUS_STACK_INGRESS_CLASS_NAME\"
  "

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .alertmanager.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .alertmanager.ingress.tls[0].hosts[0] = \"$VKPR_ENV_ALERT_MANAGER_DOMAIN\" |
      .alertmanager.ingress.tls[0].secretName = \"alertmanager-cert\"
    "
  fi

  if [[ "$VKPR_ENV_ALERTMANAGER_HA" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .alertmanager.alertmanagerSpec.replicas = 3 |
      .prometheus.prometheusSpec.replicas = 3
    "
  fi

  if [[ "$VKPR_ENV_ALERTMANAGER_SSL" == "true" ]]; then
    if [[ "$VKPR_ENV_ALERTMANAGER_SSL_SECRET" == "" ]]; then
      VKPR_ENV_ALERTMANAGER_SSL_SECRET="alertmanager-certificate"
      $VKPR_KUBECTL create secret tls $VKPR_ENV_ALERTMANAGER_SSL_SECRET -n "$VKPR_ENV_ALERTMANAGER_NAMESPACE" \
        --cert="$VKPR_ENV_ALERTMANAGER_CERTIFICATE" \
        --key="$VKPR_ENV_ALERTMANAGER_KEY"
    fi
    YQ_VALUES="$YQ_VALUES |
      .alertmanager.ingress.tls[0].hosts[0] = \"$VKPR_ENV_ALERT_MANAGER_DOMAIN\" |
      .alertmanager.ingress.tls[0].secretName = \"$VKPR_ENV_ALERTMANAGER_SSL_SECRET\"
     "
  fi

}

settingPrometheusStackEnvironment() {
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    # YQ_VALUES="$YQ_VALUES"
  fi
}
