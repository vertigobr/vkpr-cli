#!/bin/bash

validatePostgresqlPassword() {
  if $(validatePwd $1); then
    return
  else
    error "Week Postgresql Password, we recommend change the credential with the command $(bold "rit set credential")."
  fi
}