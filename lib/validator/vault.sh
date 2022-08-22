#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Vault validators
# -----------------------------------------------------------------------------

validateVaultDomain() {
  if $(validateDomain $1); then
    return
  else
    error "The value used for VKPR_ENV_GLOBAL_DOMAIN \"$1\" is invalid:  the VKPR_ENV_GLOBAL_DOMAIN must consist of a lower case alphanumeric  characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example-vkpr.com', regex used for validation is ^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9].)+([a-zA-Z]{2,})|localhost$)"
    exit
  fi
}

validateVaultSecure() {
  if $(validateBool "$1"); then
    return
  else
    error "The value used for VKPR_ENV_GLOBAL_SECURE \"$1\" is invalid: the VKPR_ENV_GLOBAL_SECURE must consist of a boolean value."
    exit
  fi
}

validateVaultStorageMode() {
  if [[ "$1" =~ ^(raft|consul)$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_VAULT_STORAGE_MODE \"$1\" is invalid: VKPR_ENV_VAULT_STORAGE_MODE must consist of raft or consul value"
    exit
  fi
}

validateVaultSSL(){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_VAULT_SSL \"$1\" is invalid: the VKPR_ENV_VAULT_SSL must consist of a boolean value."
    exit
  fi
}

validateVaultCertificate(){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_VAULT_CERTIFICATE \"$1\" is invalid: VKPR_ENV_VAULT_CERTIFICATE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. '/tmp/certificate.crt', regex used for validation is ^(\/[^\/]+){1,}\/?$)"
    exit
  fi
}

validateVaultKey(){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_VAULT_KEY \"$1\" is invalid: VKPR_ENV_VAULT_KEY must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. '/tmp/certificate.key', regex used for validation is ^(\/[^\/]+){1,}\/?$)"
    exit
  fi
}
