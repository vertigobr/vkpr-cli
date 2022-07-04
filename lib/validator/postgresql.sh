#!/bin/bash

validatePostgresqlPassword() {
  if $(validatePwd $1); then
    return
  else
    error "Week Postgresql Password, we recommend change the credential with the command $(bold "rit set credential")."
  fi
}

validatePostgresqlHA() {
  if $(validateBool $1); then
    return
  else
    error "Invalid input to HA"
  fi
}

validatePostgresqlMetrics() {
  if $(validateBool $1); then
    return
  else
    error "Invalid input to Metrics"
  fi
}