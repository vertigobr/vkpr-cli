#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Loki validators
# -----------------------------------------------------------------------------

validateLokiMetrics (){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_LOKI_METRICS \"$1\" is invalid: the VKPR_ENV_LOKI_METRICS must consist of a boolean value."
    exit
  fi
}

validateLokiPersistence (){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_LOKI_PERSISTANCE \"$1\" is invalid: the VKPR_ENV_LOKI_PERSISTANCE must consist of a boolean value."
    exit
  fi
}

validateLokiNamespace (){
  if $(validateNamespace $1); then
      return
  else
    error "The value used for VKPR_ENV_LOKI_NAMESPACE \"$1\" is invalid: VKPR_ENV_LOKI_NAMESPACE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'loki', regex used for validation is ^([A-Za-z0-9-]+)$)"
    exit
  fi
}
