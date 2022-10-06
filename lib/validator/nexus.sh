#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Nexus validators
# -----------------------------------------------------------------------------

validateNexusDomain (){
  if  $(validateDomain $1); then
    return
  else
    error "The value used for VKPR_ENV_GLOBAL_DOMAIN \"$1\" is invalid: the VKPR_ENV_GLOBAL_DOMAIN must consist of a lower case alphanumeric  characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example-vkpr.com', regex used for validation is ^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9].)+([a-zA-Z]{2,})|localhost$)"
    exit
  fi
}

validateNexusSecure (){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_GLOBAL_SECURE \"$1\" is invalid: the VKPR_ENV_GLOBAL_SECURE must consist of a boolean value."
    exit
  fi
}

validateNexusMetrics (){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_NEXUS_METRICS \"$1\" is invalid: the VKPR_ENV_NEXUS_METRICS must consist of a boolean value."
    exit
  fi
}

validateNexusPwd() {
  if $(validatePwd $1); then
    return
  else
    error "The value used for VKPR_ENV_NEXUS_ROOT_PASSWORD \"$1\" is invalid: VKPR_ENV_NEXUS_ROOT_PASSWORD must consist of lowercase, uppercase or alphanumeric characters, (e.g. 'vkpr123', regex used for validation is ^([A-Za-z0-9-]{7,})$)"
    exit
  fi
}


validateNexusIngressClassName (){
  if [[ "$1" =~ ^([a-z]+)$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_NEXUS_INGRESS_CLASS_NAME \"$1\" is invalid: VKPR_ENV_NEXUS_INGRESS_CLASS_NAME must consist of lowercase alphanumeric characters, (e.g. 'nginx', regex used for validation is ^([a-z]+)$)"
    exit
  fi
}

validateNexusNamespace (){
  if $(validateNamespace $1); then
    return
  else
    error "The value used for VKPR_ENV_NEXUS_NAMESPACE \"$1\" is invalid: VKPR_ENV_NEXUS_NAMESPACE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'nexus', regex used for validation is ^([A-Za-z0-9-]+)$)"
    exit
  fi
}

validateNexusPersistance (){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_NEXUS_PERSISTANCE \"$1\" is invalid: the VKPR_ENV_NEXUS_PERSISTANCE must consist of a boolean value."
    exit
  fi
}


validateNexusSsl (){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_NEXUS_SSL \"$1\" is invalid: the VKPR_ENV_NEXUS_SSL must consist of a boolean value."
    exit
  fi
}

validateNexusSslCrtPath (){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_NEXUS_CERTIFICATE \"$1\" is invalid: VKPR_ENV_NEXUS_CERTIFICATE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. '/tmp/certificate.crt', regex used for validation is ^(\/[^\/]+){1,}\/?$')"
    exit
  fi
}

validateNexusSslKeyPath (){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_NEXUS_KEY \"$1\" is invalid: VKPR_ENV_NEXUS_KEY must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. '/tmp/certificate.key', regex used for validation is ^(\/[^\/]+){1,}\/?$')"
    exit
  fi
}
