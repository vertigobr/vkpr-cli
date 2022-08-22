#!/usr/bin/env bash

validateExternalDNSDomain() {
  if $(validateDomain $1); then
    return
  else
    error "The value used for VKPR_ENV_GLOBAL_DOMAIN \"$1\" is invalid:  the VKPR_ENV_GLOBAL_DOMAIN must consist of a lower case alphanumeric  characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'externaldns.localhost', regex used for validation is '^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9].)+([a-zA-Z]{2,})|localhost$'). "
    exit
  fi
}

validateExternalDNSNamespace() {
  if $(validateNamespace "$1"); then
    return
  else
    error "The value used for VKPR_ENV_EXTERNAL_DNS_NAMESPACE \"$1\" is invalid: VKPR_ENV_EXTERNAL_DNS_NAMESPACE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'externaldns', regex used for validation is ^([A-Za-z0-9-]+)$')"
    exit
  fi
}

validateExternalDNSMetrics() {
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_EXTERNAL_DNS_METRICS \"$1\" is invalid:  the VKPR_ENV_EXTERNAL_DNS_METRICS must consist of a boolean value."
    exit
  fi
}
