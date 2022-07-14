#!/bin/bash

# -----------------------------------------------------------------------------
# Prometheus-Stack validators
# -----------------------------------------------------------------------------

validatePrometheusDomain() {
  if $(validateDomain $1); then
    return
  else
    error "Please correctly enter the domain to be used."
    exit
  fi
}

validatePrometheusSecure() {
  if $(validateBool "$1"); then
    return
  else
    error "It was not possible to identify if the application will have HTTPS."
    exit
  fi
}

validatePrometheusIngressClassName(){
  if [[ "$1" =~ ^([a-z]+)$ ]]; then
   return
  else
    error "Please correctly enter the ingress class name."
    exit
  fi 
}

validatePrometheusNamespace(){
  if $(validateNamespace "$1"); then
    return
  else
    error "It was not possible to identify the namespace."
    exit
  fi 
}

validateAlertManagerEnabled() {
  if $(validateBool "$1"); then
    return
  else
    error "Specifies if the application will have Alert Manager."
    exit
  fi
}

validateAlertManagerHA(){
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will have High Availability"
    exit
  fi
}

validateAlertManagerSSL(){
  if $(validateBool $1); then
    return
  else
    error "Specifies if the application will have Alert Manager SSL."
    exit
  fi
}

validateAlertManagerCertificate(){
  if $(validatePath $1); then
    return
  else
    error "Invalid path for AlertManager SSL .crt file."
    exit
  fi
}

validateAlertManagerKey(){
  if $(validatePath $1); then
    return
  else
    error "Invalid path for AlertManager SSL .key file."
    exit
  fi
}

validateAlertManagerSecret(){
  if [[ "$1" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]]; then
    return
  else
    error "Invalid SSL Secret."
    exit
  fi
}

validateGrafanaPwd() {
  if $(validatePwd $1); then
    return
  else
    error "Invalid password."
    exit
  fi
}

validatePrometheusK8S(){
  if $(validateBool $1); then
    return
  else
    error "Specifies if the application will have Prometheus K8S."
    exit
  fi
}

validateGrafanaPersistance(){
  if $(validateBool $1); then
    return
  else
    error "Specifies if the application will have Grafana Persistance."
    exit
  fi
}

validateGrafanaSSL(){
  if $(validateBool $1); then
    return
  else
    error "Specifies if the application will have Alert Manager SSL."
    exit
  fi
}

validateGrafanaCertificate(){
  if $(validatePath $1); then
    return
  else
    error "Invalid path for Grafana SSL .crt file."
    exit
  fi
}

validateGrafanaKey(){
  if $(validatePath $1); then
    return
  else
    error "Invalid path for Grafana SSL .key file."
    exit
  fi
}

validateGrafanaSecret(){
  if [[ "$1" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]]; then
    return
  else
    error "Invalid SSL Secret."
    exit
  fi
}

validatePrometheusPersistance(){
  if $(validateBool $1); then
    return
  else
    error "Specifies if the application will have Prometheus Persistance."
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