#!/usr/bin/env bash

validateCertManagerEmail() {
  if $(validateEmail $1); then
    return
  else
    error "The value used for VKPR_ENV_CERT_MANAGER_EMAIL "$VKPR_ENV_CERT_MANAGER_EMAIL" is invalid: VKPR_ENV_CERT_MANAGER_EMAIL must consist of lowercase, alphanumeric characters and '.', (e.g. 'vkpr@exemplo.com', regex used for validation is ^[a-z0-9.]+@[a-z0-9]+\.[a-z]+(\.[a-z]+)?$."
    exit
  fi
}

validateIssuerType(){
  if [[  "$1" =~ ^(staging|production)$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_CERT_MANAGER_ISSUER_TYPE "$VKPR_ENV_CERT_MANAGER_ISSUER_TYPE" is invalid: VKPR_ENV_CERT_MANAGER_ISSUER_TYPE must consist of must consist of staging or production value."
    exit
  fi
}

validateIssuerSolver(){
  if [[ "$1" =~ ^(HTTP01|DNS01)$ ]]; then
    return
  else
    error "VKPR_ENV_CERT_MANAGER_ISSUER_SOLVER "$VKPR_ENV_CERT_MANAGER_ISSUER_SOLVER" is invalid: VKPR_ENV_CERT_MANAGER_ISSUER_SOLVER must consist of HTTP01 or DNS01 value."
    exit
  fi
}
