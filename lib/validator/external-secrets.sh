#!/usr/bin/env bash


validateExternalSecretNamespace() {
  if $(validateNamespace "$1"); then
    return
  else
    error "The value used for VKPR_ENV_EXTERNAL_SECRETS_NAMESPACE \"$1\" is invalid: VKPR_ENV_EXTERNAL_SECRETS_NAMESPACE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'externalSecret', regex used for validation is ^([A-Za-z0-9-]+)$')"
    exit
  fi
}

validateExternalSecretMetrics() {
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_EXTERNAL_SECRETS_METRICS \"$1\" is invalid:  the VKPR_ENV_EXTERNAL_SECRETS_METRICS must consist of a boolean value."
    exit
  fi
}

# validateSecretStoreAddr (){}

validateSecretStorePath (){
  if $(validatePath $1); then
      return
  else
      error "The value used for VAULT_SECRET_PATH \"$1\" is invalid: VAULT_SECRET_PATH must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. '/kv/secret', regex used for validation is ^(\/[^\/]+){1,}\/?$')"
      exit
  fi
}

validateSecretStoreNamespace (){
  if $(validateNamespace "$1"); then
    return
  else
    error "The value used for SECRET_STORE_NAMESPACE \"$1\" is invalid: SECRET_STORE_NAMESPACE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'vkpr', regex used for validation is ^([A-Za-z0-9-]+)$')"
    exit
  fi
}
