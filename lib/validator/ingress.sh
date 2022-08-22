#!/usr/bin/env bash

validateIngressMetrics() {
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_INGRESS_METRICS \"$1\" is invalid: the VKPR_ENV_INGRESS_METRICS must consist of a boolean value."
    exit
  fi
}

validateIngressNamespace(){
  if $(validateNamespace "$1"); then
    return
  else
    error "The value used for VKPR_ENV_INGRESS_NAMESPACE \"$1\" is invalid: VKPR_ENV_INGRESS_NAMESPACE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'ingress', regex used for validation is ^([A-Za-z0-9-]+)$')"
    exit
  fi
}

validateIngressSSL(){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_INGRESS_SSL \"$1\" is invalid: the VKPR_ENV_INGRESS_SSL must consist of a boolean value."
    exit
  fi
}

validateIngressCertificate(){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_INGRESS_CERTIFICATE \"$1\" is invalid: VKPR_ENV_INGRESS_CERTIFICATE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. '/tmp/certificate.crt', regex used for validation is ^(\/[^\/]+){1,}\/?$')"
    exit
  fi
}

validateIngressKey(){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_INGRESS_KEY \"$VKPR_ENV_INGRESS_KEY\" is invalid: VKPR_ENV_INGRESS_KEY must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. '/tmp/certificate.key', regex used for validation is ^(\/[^\/]+){1,}\/?$')"
    exit
  fi
}
