#!/usr/bin/env bash

validateKongDomain() {
  if $(validateDomain $1); then
    return
  else
    error "The value used for VKPR_ENV_GLOBAL_DOMAIN \"$1\" is invalid: the VKPR_ENV_GLOBAL_DOMAIN must consist of a lower case alphanumeric  characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example-vkpr.com', regex used for validation is '^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9].)+([a-zA-Z]{2,})|localhost$)."
    exit
  fi
}

validateKongSecure() {
  if $(validateBool "$1"); then
    return
  else
    error "The value used for VKPR_ENV_GLOBAL_SECURE \"$1\" is invalid: the VKPR_ENV_GLOBAL_SECURE must consist of a boolean value."
    exit
  fi
}

validateKongHA(){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_KONG_HA \"$1\" is invalid: the VKPR_ENV_KONG_HA must consist of a boolean value."
    exit
  fi
}

validateKongMetrics(){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_KONG_METRICS \"$1\" is invalid: the VKPR_ENV_KONG_METRICS must consist of a boolean value."
    exit
  fi
}

validateKongEnterpriseLicensePath() {
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_KONG_ENTERPRISE_LICENSE \"$1\" is invalid: VKPR_ENV_KONG_ENTERPRISE_LICENSE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. '/tmp/license.json', regex used for validation is ^(\/[^\/]+){1,}\/?$)"
    exit
  fi
}

validateKongRBACPwd() {
  if $(validatePwd $1); then
    return
  else
    error "The value used for VKPR_ENV_KONG_RBAC_ADMIN_PASSWORD \"$1\" is invalid: VKPR_ENV_KONG_RBAC_ADMIN_PASSWORD must consist of lowercase, uppercase or alphanumeric characters, (e.g. 'vkpr123', regex used for validation is ^([A-Za-z0-9-]{7,})$)"
    exit
  fi
}

validateKongDeployment() {
  if [[ "$1" =~ ^(standard|hybrid|dbless)$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_KONG_MODE \"$1\" is invalid: VKPR_ENV_KONG_MODE must consist of standard, hybrid or dbless value"
    exit
  fi
}

validateKongNamespace() {
  if  $(validateNamespace $1); then
    return
  else
    error "The value used for VKPR_ENV_KONG_NAMESPACE \"$1\" is invalid: VKPR_ENV_KONG_NAMESPACE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'kong', regex used for validation is ^([A-Za-z0-9-]+)$)"
    exit
  fi
}

validateKongAddr (){
  if $(validateUrl $1); then
    return
  else
    error "The value used for VKPR_ENV_KONG_ADDR \"$1\" is invalid: the VKPR_ENV_KONG_ADDR must consist of a lower case alphanumeric  characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'http://admin.localhost:8000', regex used for validation is '^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9].)+([a-zA-Z]{2,})|localhost$)."
    exit
  fi
}

validateKongAdminToken (){
  if $(validatePwd $1); then
    return
  else
    error "The value used for VKPR_ENV_KONG_ADMIN_TOKEN \"$1\" is invalid: VKPR_ENV_KONG_ADMIN_TOKEN must consist of lowercase, uppercase or alphanumeric characters, (e.g. 'vkpr123', regex used for validation is ^([A-Za-z0-9-]{7,})$)"
    exit
  fi
}

validateKongWorkspace (){
  if  $(validateNamespace $1); then
    return
  else
    error "The value used for VKPR_ENV_KONG_WORKSPACE \"$1\" is invalid: VKPR_ENV_KONG_WORKSPACE must consist of lowercase or '-' alphanumeric characters, (e.g. 'kong', regex used for validation is ^([a-z0-9]([-a-z0-9]*[a-z0-9])?)$)"
    exit
  fi
}

validateKongYamlPath (){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_KONG_YAML_PATH \"$1\" is invalid: VKPR_ENV_KONG_YAML_PATH  must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. '/tmp/license.json', regex used for validation is ^(\/[^\/]+){1,}\/?$)"
    exit
  fi
}