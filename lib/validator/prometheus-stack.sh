#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Prometheus-Stack validators
# -----------------------------------------------------------------------------

validatePrometheusDomain() {
  if $(validateDomain $1); then
    return
  else
    error "The value used for VKPR_ENV_GLOBAL_DOMAIN \"$1\" is invalid:  the VKPR_ENV_GLOBAL_DOMAIN must consist of a lower case alphanumeric  characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example-vkpr.com', regex used for validation is ^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9].)+([a-zA-Z]{2,})|localhost$)."
    exit
  fi
}

validatePrometheusSecure() {
  if $(validateBool "$1"); then
    return
  else
    error "The value used for VKPR_ENV_GLOBAL_SECURE \"$1\" is invalid:  the VKPR_ENV_GLOBAL_SECURE must consist of a boolean value."
    exit
  fi
}

validatePrometheusIngressClassName(){
  if [[ "$1" =~ ^([a-z]+)$ ]]; then
   return
  else
    error "The value used for VKPR_ENV_PROMETHEUS_STACK_INGRESS_CLASS_NAME \"$1\" is invalid: VKPR_ENV_PROMETHEUS_STACK_INGRESS_CLASS_NAME must consist of lowercase, (e.g. 'prometheus', regex used for validation is ^([a-z]+)$)"
    exit
  fi
}

validatePrometheusNamespace(){
  if $(validateNamespace "$1"); then
    return
  else
    error "The value used for VKPR_ENV_PROMETHEUS_STACK_NAMESPACE \"$1\" is invalid: VKPR_ENV_PROMETHEUS_STACK_NAMESPACE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'prometheus-stack', regex used for validation is ^([A-Za-z0-9-]+)$)"
    exit
  fi
}

validateAlertManagerEnabled() {
  if $(validateBool "$1"); then
    return
  else
    error "The value used for VKPR_ENV_ALERTMANAGER \"$1\" is invalid:  the VKPR_ENV_ALERTMANAGER must consist of a boolean value."
    exit
  fi
}

validatePrometheusHA(){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_PROMETHEUS_STACK_HA \"$1\" is invalid:  the VKPR_ENV_PROMETHEUS_STACK_HA must consist of a boolean value."
    exit
  fi
}

validateAlertManagerSSL(){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_ALERTMANAGER_SSL \"$1\" is invalid:  the VKPR_ENV_ALERTMANAGER_SSL must consist of a boolean value."
    exit
  fi
}

validateAlertManagerCertificate(){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_ALERTMANAGER_CERTIFICATE \"$1\" is invalid: VKPR_ENV_ALERTMANAGER_CERTIFICATE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. '/tmp/certificate.crt', regex used for validation is ^(\/[^\/]+){1,}\/?$)"
    exit
  fi
}

validateAlertManagerKey(){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_ALERTMANAGER_KEY \"$1\" is invalid: VKPR_ENV_ALERTMANAGER_KEY must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. '/tmp/certificate.key', regex used for validation is ^(\/[^\/]+){1,}\/?$)"
    exit
  fi
}

validateAlertManagerSecret(){
  if [[ "$1" =~ ""|^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]]; then
    return
  else
    error "Invalid AlertManager-SSL Secret."
    exit
  fi
}

validateAlertManagerPersistance(){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_ALERTMANAGER_PERSISTANCE \"$1\" is invalid:  the VKPR_ENV_ALERTMANAGER_PERSISTANCE must consist of a boolean value."
    exit
  fi
}

validateGrafanaPwd() {
  if $(validatePwd $1); then
    return
  else
    error "The value used for VKPR_ENV_GRAFANA_PASSWORD \"$1\" is invalid: VKPR_ENV_GRAFANA_PASSWORD must consist of lowercase, uppercase or alphanumeric characters, (e.g. 'vkpr123', regex used for validation is ^([A-Za-z0-9-]{7,})$)"
    exit
  fi
}

validatePrometheusK8S(){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_PROMETHEUS_STACK_K8S_EXPORTERS \"$1\" is invalid:  the VKPR_ENV_PROMETHEUS_STACK_K8S_EXPORTERS must consist of a boolean value."
    exit
  fi
}

validateGrafanaPersistance(){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_GRAFANA_PERSISTANCE \"$1\" is invalid:  the VKPR_ENV_GRAFANA_PERSISTANCE must consist of a boolean value."
    exit
  fi
}

validateGrafanaSSL(){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_GRAFANA_SSL \"$1\" is invalid:  the VKPR_ENV_GRAFANA_SSL must consist of a boolean value."
    exit
  fi
}

validateGrafanaCertificate(){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_GRAFANA_CERTIFICATE \"$1\" is invalid: VKPR_ENV_GRAFANA_CERTIFICATE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'vkpr/grafana/certificate.crt', regex used for validation is ^(\/[^\/]+){1,}\/?$')"
    exit
  fi
}

validateGrafanaKey(){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_GRAFANA_KEY \"$1\" is invalid: VKPR_ENV_GRAFANA_KEY must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'vkpr/grafana/certificate.key', regex used for validation is ^(\/[^\/]+){1,}\/?$')"
    exit
  fi
}

validateGrafanaSecret(){
  if [[ "$1" =~ ""|^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]]; then
    return
  else
    error "Invalid Grafana-SSL Secret."
    exit
  fi
}

validatePrometheusEnabled() {
  if $(validateBool "$1"); then
    return
  else
    error "The value used for VKPR_ENV_PROMETHEUS \"$1\" is invalid:  the VKPR_ENV_PROMETHEUS must consist of a boolean value."
    exit
  fi
}

validatePrometheusSSL(){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_PROMETHEUS_SSL \"$1\" is invalid:  the VKPR_ENV_PROMETHEUS_SSL must consist of a boolean value."
    exit
  fi
}

validatePrometheusCertificate(){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_PROMETHEUS_CERTIFICATE "$VKPR_ENV_PROMETHEUS_CERTIFICATE" is invalid: VKPR_ENV_PROMETHEUS_CERTIFICATE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'vkpr/prometheus-stack/certificate.crt', regex used for validation is ^(\/[^\/]+){1,}\/?$')"
    exit
  fi
}

validatePrometheusKey(){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_PROMETHEUS_KEY \"$1\" is invalid: VKPR_ENV_PROMETHEUS_KEY must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'vkpr/prometheus-stack/certificate.key', regex used for validation is ^(\/[^\/]+){1,}\/?$')"
    exit
  fi
}

validatePrometheusSecret(){
  if [[ "$1" =~ ""|^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]]; then
    return
  else
    error "Invalid Prometheus-SSL Secret."
    exit
  fi
}

validatePrometheusPersistance(){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_PROMETHEUS_PERSISTANCE \"$1\" is invalid:  the VKPR_ENV_PROMETHEUS_PERSISTANCE must consist of a boolean value."
    exit
  fi
}

validateLokiNamespace(){
  if [[ "$1" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]]; then
    return
  else
    error "It was not possible to identify the namespace."
    exit
  fi
}

validatePrometheusImportDashboardPath(){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_DASHBOARD_PATH \"$1\" is invalid: VKPR_ENV_DASHBOARD_PATH must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. '/tmp/dashboard.json', regex used for validation is ^(\/[^\/]+){1,}\/?$)"
    exit
  fi
}

validatePrometheusVolumeSize(){
  if $(validateVolume $1); then
    return
  else
    error "The value used for VKPR_ENV_PROMETHEUS_VOLUME_SIZE \"$1\" is invalid: VKPR_ENV_PROMETHEUS_VOLUME_SIZE must consist of alphanumeric characters ending with \"Gi\", (e.g. '10Gi', regex used for validation is ^([0-9]{1,4}+Gi)$)"
    exit
  fi
}

validateGrafanaVolumeSize(){
  if $(validateVolume $1); then
    return
  else
    error "The value used for VKPR_ENV_GRAFANA_VOLUME_SIZE \"$1\" is invalid: VKPR_ENV_GRAFANA_VOLUME_SIZE must consist of alphanumeric characters ending with \"Gi\", (e.g. '10Gi', regex used for validation is ^([0-9]{1,4}+Gi)$)"
    exit
  fi
}

validateAlertManagerVolumeSize(){
  if $(validateVolume $1); then
    return
  else
    error "The value used for VKPR_ENV_PROMETHEUS_VOLUME_SIZE \"$1\" is invalid: VKPR_ENV_PROMETHEUS_VOLUME_SIZE must consist of alphanumeric characters ending with \"Gi\", (e.g. '10Gi', regex used for validation is ^([0-9]{1,4}+Gi)$)"
    exit
  fi
}