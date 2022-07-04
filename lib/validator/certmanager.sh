#!/bin/bash

validateCertManagerEmail() {
  if $(validateEmail $1); then
    return
  else
    error "Invalid email"
  fi
}

validateIssuerType(){
  if [[  "$1" =~ ^staging|production$ ]]; then
    return
  else
    error "It was not possible to identify what is the cluster issuer"
  fi
}

validateIssuerSolver(){
  if [[ "$1" =~ ^HTTP01|DNS01$ ]]; then
    return
  else
    error "It was not possible to identify what type of challenge you will use to issue the certificate"
  fi
}