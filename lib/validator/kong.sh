#!/usr/bin/env bash

validateKongDomain() {
  if $(validateDomain $1); then
    return
  else
    error "The value used for VKPR_ENV_GLOBAL_DOMAIN "$VKPR_ENV_GLOBAL_DOMAIN" is invalid:  the VKPR_ENV_GLOBAL_DOMAIN must consist of a lower case alphanumeric  characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'kong.localhost', regex used for validation is '^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9].)+([a-zA-Z]{2,})|localhost$')."
    exit
  fi
}

validateKongSecure() {
  if $(validateBool "$1"); then
    return
  else
    error "The value used for VKPR_ENV_GLOBAL_SECURE "$VKPR_ENV_GLOBAL_SECURE" is invalid:  the VKPR_ENV_GLOBAL_SECURE must consist of a boolean value."
    exit
  fi
}

validateKongHA(){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_KONG_HA "$VKPR_ENV_KONG_HA" is invalid:  the VKPR_ENV_KONG_HA must consist of a boolean value."
    exit
  fi
}

validateKongMetrics(){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_KONG_METRICS "$VKPR_ENV_KONG_METRICS" is invalid:  the VKPR_ENV_KONG_METRICS must consist of a boolean value."
    exit
  fi
}

validateKongEnterprise() {
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_KONG_ENTERPRISE "$VKPR_ENV_KONG_ENTERPRISE" is invalid:  the VKPR_ENV_KONG_ENTERPRISE must consist of a boolean value."
    exit
  fi
}

validateKongEnterpriseLicensePath() {
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_KONG_ENTERPRISE_LICENSE "$VKPR_ENV_KONG_ENTERPRISE_LICENSE" is invalid: VKPR_ENV_KONG_ENTERPRISE_LICENSE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'vkpr/kong/enterpriselicense.crt', regex used for validation is ^(\/[^\/]+){1,}\/?$')"
    exit
  fi
}

validateKongRBACPwd() {
  if $(validatePwd $1); then
    return
  else
    error "The value used for VKPR_ENV_KONG_RBAC_ADMIN_PASSWORD "$VKPR_ENV_KONG_RBAC_ADMIN_PASSWORD" is invalid: VKPR_ENV_KONG_RBAC_ADMIN_PASSWORD must consist of lowercase, uppercase or alphanumeric characters, (e.g. 'vkpr123', regex used for validation is ^([A-Za-z0-9-]{7,})$')"
    exit
  fi
}

validateKongDeployment() {
  if [[ "$1" =~ ^(standard|hybrid|dbless)$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_KONG_MODE "$VKPR_ENV_KONG_MODE" is invalid: VKPR_ENV_KONG_MODE must consist of standard or hybrid or dbless value"
    exit
  fi
}

validateKongNamespace() {
  if  $(validateNamespace $1); then
    return
  else
    error "The value used for VKPR_ENV_KONG_NAMESPACE "$VKPR_ENV_KONG_NAMESPACE" is invalid: VKPR_ENV_KONG_NAMESPACE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'kong', regex used for validation is ^([A-Za-z0-9-]+)$')"
    exit
  fi
}
