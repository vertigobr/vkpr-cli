#!/usr/bin/env bash

validatePostgresqlPassword() {
  if $(validatePwd $1); then
    return
  else
    error "The value used for PG_PASSWORD \"$1\" is invalid: PG_PASSWORD must consist of lowercase, uppercase or alphanumeric characters, (e.g. 'vkpr123', regex used for validation is ^([A-Za-z0-9-]{7,})$)"
    exit
  fi
}

validatePostgresqlHA() {
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_POSTGRESQL_HA \"$1\" is invalid: the VKPR_ENV_POSTGRESQL_HA must consist of a boolean value."
    exit
  fi
}

validatePostgresqlMetrics() {
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_POSTGRESQL_METRICS \"$1\" is invalid: the VKPR_ENV_POSTGRESQL_METRICS must consist of a boolean value."
    exit
  fi
}

validatePostgresqlNamespace(){
  if $(validateNamespace $1); then
    return
  else
    error "The value used for VKPR_ENV_POSTGRESQL_NAMESPACE \"$1\" is invalid: VKPR_ENV_POSTGRESQL_NAMESPACE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'postgresql', regex used for validation is ^([A-Za-z0-9-]+)$)"
    exit
  fi
}

validateDbName (){
  if $(validateNamespace $1); then
    return
  else
    error "The value used for VKPR_ENV_DB_NAME \"$1\" is invalid: VKPR_ENV_DB_NAME must consist of lowercase or alphanumeric characters, (e.g. 'postgresql', regex used for validation is ^([a-z0-9]([-a-z0-9]*[a-z0-9])?)$ )"
    exit
  fi  
}

validateDbUser (){
  if $(validateNamespace $1); then
    return
  else
    error "The value used for VKPR_ENV_DB_USER \"$1\" is invalid: VKPR_ENV_DB_USER must consist of lowercase or alphanumeric characters, (e.g. 'postgresql', regex used for validation is ^([a-z0-9]([-a-z0-9]*[a-z0-9])?)$ )"
    exit
  fi  
}

validateDbPassword (){
  if $(validatePwd $1); then
    return
  else
    error "The value used for VKPR_ENV_DB_PASSWORD \"$1\" is invalid: VKPR_ENV_DB_PASSWORD must consist of lowercase or alphanumeric characters, (e.g. 'vkpr123', regex used for validation is ^([A-Za-z0-9-]{7,})$)"
    exit
  fi
}

validatePostgresqlVolumeSize(){
  if $(validateVolume $1); then
    return
  else
    error "The value used for VKPR_ENV_POSTGRESQL_VOLUME_SIZE \"$1\" is invalid: VKPR_ENV_POSTGRESQL_VOLUME_SIZE must consist of alphanumeric characters ending with \"Gi\", (e.g. '10Gi', regex used for validation is ^([0-9]{1,4}+Gi)$)"
    exit
  fi
}