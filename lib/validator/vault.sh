#!/bin/bash

# -----------------------------------------------------------------------------
# Vault validators
# -----------------------------------------------------------------------------

validateVaultDomain() {
  if $(validateDomain $1); then
    return
  else
    error "Please correctly enter the domain to be used."
    exit
  fi
}

validateVaultSecure() {
  if $(validateBool "$1"); then
    return
  else
    error "It was not possible to identify if the application will have HTTPS."
    exit
  fi
}

validateVaultStorageMode() {
  if [[ "$1" =~ ^(raft|consul)$ ]]; then
    return
  else
    error "Specifies the Vault storage mode"
    exit
  fi
}

validateVaultSSL(){
  if $(validateBool $1); then
    return
  else
    error "Specifies if the application will have Vault SSL."
    exit
  fi
}

validateVaultCertificate(){
  if $(validatePath $1); then
    return
  else
    error "Invalid path for Vault SSL .crt file."
    exit
  fi
}

validateVaultKey(){
  if $(validatePath $1); then
    return
  else
    error "Invalid path for Vault SSL .key file."
    exit
  fi
}