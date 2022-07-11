#!/bin/bash

validatePostgresqlPassword() {
  if $(validatePwd $1); then
    return
  else
    error 'Week Postgresql Password, we recommend change the credential with the command "rit set credential".'
    exit
  fi
}

validatePostgresqlHA() {
  if $(validateBool $1); then
    return
  else
    error "Invalid input to HA"
    exit
  fi
}

validatePostgresqlMetrics() {
  if $(validateBool $1); then
    return
  else
    error "Invalid input to Metrics"
    exit
  fi
}

validatePostgresqlNamespace(){
  if $(validateNamespace $1); then
    return
  else
    error "Invalid input to Namespace"
    exit
  fi
}