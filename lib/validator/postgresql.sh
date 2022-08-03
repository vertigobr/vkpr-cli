#!/bin/bash

validatePostgresqlPassword() {
  if $(validatePwd $1); then
    return
  else
    error "The value used for PG_PASSWORD "$PG_PASSWORD" is invalid: PG_PASSWORD must consist of lowercase, uppercase or alphanumeric characters, (e.g. 'vkpr123', regex used for validation is ^([A-Za-z0-9-]{7,})$')"
}

validatePostgresqlHA() {
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_POSTGRESQL_HA "$VKPR_ENV_POSTGRESQL_HA" is invalid:  the VKPR_ENV_POSTGRESQL_HA must consist of a boolean value."
    exit
  fi
}

validatePostgresqlMetrics() {
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_POSTGRESQL_METRICS "$VKPR_ENV_POSTGRESQL_METRICS" is invalid:  the VKPR_ENV_POSTGRESQL_METRICS must consist of a boolean value."
    exit
  fi
}

validatePostgresqlNamespace(){
  if $(validateNamespace $1); then
    return
  else
    error "The value used for VKPR_ENV_POSTGRESQL_NAMESPACE "$VKPR_ENV_POSTGRESQL_NAMESPACE" is invalid: VKPR_ENV_POSTGRESQL_NAMESPACE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'postgresql', regex used for validation is ^([A-Za-z0-9-]+)$')"
    exit
  fi
}