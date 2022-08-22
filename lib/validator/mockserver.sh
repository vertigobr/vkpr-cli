#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Mockserver validators
# -----------------------------------------------------------------------------


validateMockServerDomain() {
  if $(validateDomain $1); then
    return
  else
    error "The value used for VKPR_ENV_GLOBAL_DOMAIN \"$1\" is invalid:  the VKPR_ENV_GLOBAL_DOMAIN must consist of a lower case alphanumeric  characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example-vkpr.com', regex used for validation is ^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9].)+([a-zA-Z]{2,})|localhost$)"
    exit
  fi
}

validateMockServerSecure() {
  if $(validateBool "$1"); then
    return
  else
    error "The value used for VKPR_ENV_GLOBAL_SECURE \"$1\" is invalid:  the VKPR_ENV_GLOBAL_SECURE must consist of a boolean value."
    exit
  fi
}

validateMockServerIngressClassName(){
  if [[ "$1" =~ ^([a-z]+)$ ]]; then
   return
  else
    error "The value used for VKPR_ENV_MOCKSERVER_INGRESS_CLASS_NAME \"$1\" is invalid: VKPR_ENV_MOCKSERVER_INGRESS_CLASS_NAME must consist of lowercase alphanumeric characters, (e.g. 'nginx', regex used for validation is ^([a-z]+)$)"
    exit
  fi
}

validateMockServerNamespace(){
  if $(validateNamespace "$1"); then
    return
  else
    error "The value used for VKPR_ENV_MOCKSERVER_NAMESPACE \"$1\" is invalid: VKPR_ENV_MOCKSERVER_NAMESPACE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'mockserver', regex used for validation is ^([A-Za-z0-9-]+)$)"
    exit
  fi
}

validateMockServerSSL(){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_MOCKSERVER_SSL \"$1\" is invalid:  the VKPR_ENV_MOCKSERVER_SSL must consist of a boolean value."
    exit
  fi
}

validateMockServerCertificate(){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_MOCKSERVER_CERTIFICATE \"$1\" is invalid: VKPR_ENV_MOCKSERVER_CERTIFICATE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. '/tmp/certificate.crt.crt', regex used for validation is ^(\/[^\/]+){1,}\/?$')"
    exit
  fi
}

validateMockServerKey(){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_MOCKSERVER_KEY \"$1\" is invalid: VKPR_ENV_MOCKSERVER_KEY must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. '/tmp/certificate.crt.key', regex used for validation is ^(\/[^\/]+){1,}\/?$')"
    exit
  fi
}
