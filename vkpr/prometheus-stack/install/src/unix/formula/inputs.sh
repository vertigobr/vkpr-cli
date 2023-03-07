#!/usr/bin/env bash

formulaInputs() {
  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "prometheus-stack.ingressClassName" "PROMETHEUS_STACK_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "PROMETHEUS_STACK_NAMESPACE"
  checkGlobalConfig "false" "false" "prometheus-stack.k8sExporters" "PROMETHEUS_STACK_EXPORTERS"
  checkGlobalConfig "${HA-:false}" "false" "prometheus-stack.HA" "PROMETHEUS_STACK_HA"

  ## AlertManager
  checkGlobalConfig "$ALERTMANAGER" "false" "prometheus-stack.alertManager.enabled" "ALERTMANAGER"
  if [[ "$VKPR_ENV_ALERTMANAGER" = true ]]; then
    checkGlobalConfig "false" "false" "prometheus-stack.alertManager.ssl.enabled" "ALERTMANAGER_SSL"
    checkGlobalConfig "" "" "prometheus-stack.alertManager.ssl.crt" "ALERTMANAGER_SSL_CERTIFICATE"
    checkGlobalConfig "" "" "prometheus-stack.alertManager.ssl.key" "ALERTMANAGER_SSL_KEY"
    checkGlobalConfig "" "" "prometheus-stack.alertManager.ssl.secretName" "ALERTMANAGER_SSL_SECRET"
    checkGlobalConfig "false" "false" "prometheus-stack.alertManager.persistence.enabled" "ALERTMANAGER_PERSISTENCE"
    [ "$VKPR_ENV_ALERTMANAGER_PERSISTENCE" = true ] && checkGlobalConfig "2Gi" "2Gi" "prometheus-stack.alertManager.persistence.size" "ALERTMANAGER_VOLUME_SIZE"
  fi

  ## Grafana
  checkGlobalConfig "$GRAFANA_PASSWORD" "vkpr123" "prometheus-stack.grafana.adminPassword" "GRAFANA_PASSWORD"
  checkGlobalConfig "false" "false" "prometheus-stack.grafana.persistence.enabled" "GRAFANA_PERSISTENCE"
  [ "$VKPR_ENV_GRAFANA_PERSISTENCE" = true ] && checkGlobalConfig "8Gi" "8Gi" "prometheus-stack.grafana.persistence.size" "GRAFANA_VOLUME_SIZE" 
  checkGlobalConfig "$SSL" "false" "prometheus-stack.grafana.ssl.enabled" "GRAFANA_SSL"
  if [[ "$VKPR_ENV_GRAFANA_SSL" = true ]]; then
    checkGlobalConfig "$CRT_FILE" "" "prometheus-stack.grafana.ssl.crt" "GRAFANA_SSL_CERTIFICATE"
    checkGlobalConfig "$KEY_FILE" "" "prometheus-stack.grafana.ssl.key" "GRAFANA_SSL_KEY"
    checkGlobalConfig "" "" "prometheus-stack.grafana.ssl.secretName" "GRAFANA_SSL_SECRET"
  fi

  ## Prometheus
  checkGlobalConfig "false" "false" "prometheus-stack.prometheus.enabled" "PROMETHEUS"
  checkGlobalConfig "false" "false" "prometheus-stack.prometheus.persistence.enabled" "PROMETHEUS_PERSISTENCE"
  [ "$VKPR_ENV_PROMETHEUS_PERSISTENCE" = true ] && checkGlobalConfig "8Gi" "8Gi" "prometheus-stack.prometheus.persistence.size" "PROMETHEUS_VOLUME_SIZE"  
  if [[ "$VKPR_ENV_PROMETHEUS" = true ]]; then
    checkGlobalConfig "false" "false" "prometheus-stack.prometheus.ssl.enabled" "PROMETHEUS_SSL"
    checkGlobalConfig "" "" "prometheus-stack.prometheus.ssl.crt" "PROMETHEUS_SSL_CERTIFICATE"
    checkGlobalConfig "" "" "prometheus-stack.prometheus.ssl.key" "PROMETHEUS_SSL_KEY"
    checkGlobalConfig "" "" "prometheus-stack.prometheus.ssl.secretName" "PROMETHEUS_SSL_SECRET"
  fi

  # Integrate
  checkGlobalConfig "false" "false" "prometheus-stack.grafana.openid.enabled" "GRAFANA_KEYCLOAK_OPENID"
  checkGlobalConfig "" "" "prometheus-stack.grafana.openid.clientSecret" "GRAFANA_KEYCLOAK_OPENID_CLIENTSECRET"

  # External app values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "keycloak.namespace" "KEYCLOAK_NAMESPACE"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "loki.namespace" "LOKI_NAMESPACE"

}

validateInputs() {
  # App values
  validatePrometheusDomain "$VKPR_ENV_GLOBAL_DOMAIN"
  validatePrometheusSecure "$VKPR_ENV_GLOBAL_SECURE"
  validatePrometheusIngressClassName "$VKPR_ENV_PROMETHEUS_STACK_INGRESS_CLASS_NAME"
  validatePrometheusNamespace "$VKPR_ENV_PROMETHEUS_STACK_NAMESPACE"
  validatePrometheusHA "$VKPR_ENV_PROMETHEUS_STACK_HA"

  ## AlertManager
  validateAlertManagerEnabled "$VKPR_ENV_ALERTMANAGER"
  if [[ "$VKPR_ENV_ALERTMANAGER" = true ]]; then
    validateAlertManagerSSL "$VKPR_ENV_ALERTMANAGER_SSL"
    validateAlertManagerPersistance "$VKPR_ENV_ALERTMANAGER_PERSISTENCE"
    [ "$VKPR_ENV_ALERTMANAGER_PERSISTENCE" = true ] && validateAlertManagerVolumeSize "$VKPR_ENV_ALERTMANAGER_VOLUME_SIZE"
    if [[ "$VKPR_ENV_ALERTMANAGER_SSL" = true ]]; then
      validateAlertManagerCertificate "$VKPR_ENV_ALERTMANAGER_SSL_CERTIFICATE"
      validateAlertManagerKey "$VKPR_ENV_ALERTMANAGER_SSL_KEY"
      validateAlertManagerSecret "$VKPR_ENV_ALERTMANAGER_SSL_SECRET"
    fi
  fi

  ## Grafana
  validateGrafanaPwd "$VKPR_ENV_GRAFANA_PASSWORD"
  validatePrometheusK8S "$VKPR_ENV_PROMETHEUS_STACK_EXPORTERS"
  validateGrafanaPersistance "$VKPR_ENV_GRAFANA_PERSISTENCE"
  [ "$VKPR_ENV_GRAFANA_PERSISTENCE" = true ] && validateGrafanaVolumeSize "$VKPR_ENV_GRAFANA_VOLUME_SIZE"
  validateGrafanaSSL "$VKPR_ENV_GRAFANA_SSL"
  if [[ "$VKPR_ENV_GRAFANA_SSL" = true ]]; then
    validateGrafanaCertificate "$VKPR_ENV_GRAFANA_SSL_CERTIFICATE"
    validateGrafanaKey "$VKPR_ENV_GRAFANA_SSL_KEY"
    validateGrafanaSecret "$VKPR_ENV_GRAFANA_SSL_SECRET"
  fi

  ## Prometheus
  # validatePrometheusEnabled "$VKPR_ENV_PROMETHEUS"
  if [[ "$VKPR_ENV_PROMETHEUS" = true ]]; then
    validatePrometheusSSL "$VKPR_ENV_PROMETHEUS_SSL"
    if [[ "$VKPR_ENV_PROMETHEUS_SSL" = true ]]; then
      validatePrometheusCertificate "$VKPR_ENV_PROMETHEUS_SSL_CERTIFICATE"
      validatePrometheusKey "$VKPR_ENV_PROMETHEUS_SSL_KEY"
      validatePrometheusSecret "$VKPR_ENV_PROMETHEUS_SSL_SECRET"
    fi
  fi
  validatePrometheusPersistance "$VKPR_ENV_PROMETHEUS_PERSISTENCE"
  [ "$VKPR_ENV_PROMETHEUS_PERSISTENCE" = true ] && validatePrometheusVolumeSize "$VKPR_ENV_PROMETHEUS_VOLUME_SIZE"
  # External app values
  validateLokiNamespace "$VKPR_ENV_LOKI_NAMESPACE"
}