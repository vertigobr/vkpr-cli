#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Keycloak validators
# -----------------------------------------------------------------------------

validateKeycloakDomain (){
  if $(validateDomain $1); then
    return
  else
    error "The value used for VKPR_ENV_GLOBAL_DOMAIN \"$1\" is invalid: the VKPR_ENV_GLOBAL_DOMAIN must consist of a lower case alphanumeric  characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example-vkpr.com', regex used for validation is ^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9].)+([a-zA-Z]{2,})|localhost$)"
    exit
  fi
}

validateKeycloakSecure (){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_GLOBAL_SECURE \"$1\" is invalid: the VKPR_ENV_GLOBAL_SECURE must consist of a boolean value."
    exit
  fi
}

validateKeycloakHa () {
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_KEYCLOAK_HA \"$1\" is invalid: the VKPR_ENV_KEYCLOAK_HA must consist of a boolean value."
    exit
  fi
}

validateKeycloakAdminUser (){
  if [[ "$1" =~ ^([A-Za-z0-9-]{1,})$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_KEYCLOAK_ADMIN_USER \"$1\" is invalid: VKPR_ENV_KEYCLOAK_ADMIN_USER must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'admin', regex used for validation is ^([A-Za-z0-9-]{1,})$)"
    exit
  fi
}

validateKeycloakAdminPwd (){
  if $(validatePwd $1); then
    return
  else
    error "The value used for VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD \"$1\" is invalid: VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD must consist of lowercase, uppercase or alphanumeric characters, (e.g. 'vkpr123', regex used for validation is ^([A-Za-z0-9-]{7,})$)"
    exit
  fi
}

validateKeycloakIngresClassName (){
  if [[ "$1" =~ ^([a-z]+)$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_KEYCLOAK_INGRESS_CLASS_NAME \"$1\" is invalid: VKPR_ENV_KEYCLOAK_INGRESS_CLASS_NAME must consist of lowercase, (e.g. 'nginx', regex used for validation is ^([a-z]+)$)"
    exit
  fi
}

validateKeycloakNamespace (){
  if $(validateNamespace $1); then
    return
  else
    error "The value used for VKPR_ENV_KEYCLOAK_NAMESPACE \"$1\" is invalid: VKPR_ENV_KEYCLOAK_NAMESPACE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'keycloak', regex used for validation is ^([A-Za-z0-9-]+)$)"
    exit
  fi
}

validateKeycloakSsl (){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_KEYCLOAK_SSL \"$1\" is invalid: the VKPR_ENV_KEYCLOAK_SSL must consist of a boolean value."
    exit
  fi
}

validateKeycloakCrt (){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_KEYCLOAK_CERTIFICATE \"$1\" is invalid: VKPR_ENV_KEYCLOAK_CERTIFICATE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. '/tmp/certificate.crt', regex used for validation is ^(\/[^\/]+){1,}\/?$)"
    exit
  fi
}

validateKeycloakKey (){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_KEYCLOAK_KEY \"$1\" is invalid: VKPR_ENV_KEYCLOAK_KEY must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. '/tmp/certificate.key', regex used for validation is ^(\/[^\/]+){1,}\/?$)"
    exit
  fi
}

validateKeycloakMetrics (){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_KEYCLOAK_METRICS \"$1\" is invalid: the VKPR_ENV_KEYCLOAK_METRICS must consist of a boolean value."
    exit
  fi
}
