#!/bin/bash

validateCertManagerEmail() {
  if $(validateEmail $1); then
    return
  else
    error "Invalid email, specifies your email to issue the certificate."
    exit
  fi
}

validateIssuerType(){
  if [[  "$1" =~ ^staging|production$ ]]; then
    return
  else
    error "Invalid issuer, specifies what will be used to issue certificates."
    exit
  fi
}

validateIssuerSolver(){
  if [[ "$1" =~ ^HTTP01|DNS01$ ]]; then
    return
  else
    error "Invalid issue Solver, specifies the type of challenge you will use to issue the certificate."
    exit
  fi
}