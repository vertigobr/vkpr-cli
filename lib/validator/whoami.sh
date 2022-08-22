#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Whoami validators
# -----------------------------------------------------------------------------

validateWhoamiDomain (){
  if  $(validateDomain $1); then
    return
  else
    error "The value used for VKPR_ENV_GLOBAL_DOMAIN \"$1\" is invalid:  the VKPR_ENV_GLOBAL_DOMAIN must consist of a lower case alphanumeric  characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example-vkpr.com', regex used for validation is ^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9].)+([a-zA-Z]{2,})|localhost$)"
    exit
  fi
}

validateWhoamiSecure (){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_GLOBAL_SECURE \"$1\" is invalid: the VKPR_ENV_GLOBAL_SECURE must consist of a boolean value."
    exit
  fi
}

validateWhoamiSsl (){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_WHOAMI_SSL \"$1\" is invalid: the VKPR_ENV_WHOAMI_SSL must consist of a boolean value."
    exit
  fi
}

validateWhoamiSslCrtPath (){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_WHOAMI_SSL_CERTIFICATE \"$1\" is invalid: VKPR_ENV_WHOAMI_SSL_CERTIFICATE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. '/tmp/certificate.crt', regex used for validation is ^(\/[^\/]+){1,}\/?$)"
    exit
  fi
}

validateWhoamiSslKeyPath (){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_WHOAMI_SSL_KEY \"$1\" is invalid: VKPR_ENV_WHOAMI_SSL_KEY must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. '/tmp/certificate.key', regex used for validation is ^(\/[^\/]+){1,}\/?$)"
    exit
  fi
}
