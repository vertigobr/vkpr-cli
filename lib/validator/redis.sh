#!/usr/bin/env bash

validateRedisPassword() {
  if $(validatePwd $1); then
    return
  else
    error "The value used for REDIS_PASSWORD \"$1\" is invalid: REDIS_PASSWORD must consist of lowercase, uppercase or alphanumeric characters, (e.g. 'vkpr123', regex used for validation is ^([A-Za-z0-9-]{7,})$)"
    exit
  fi
}

validateRedisMetrics() {
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_REDIS_METRICS \"$1\" is invalid: the VKPR_ENV_REDIS_METRICS must consist of a boolean value."
    exit
  fi
}

validateRedisNamespace(){
  if $(validateNamespace $1); then
    return
  else
    error "The value used for VKPR_ENV_REDIS_NAMESPACE \"$1\" is invalid: VKPR_ENV_REDIS_NAMESPACE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'redis', regex used for validation is ^([A-Za-z0-9-]+)$)"
    exit
  fi
}
