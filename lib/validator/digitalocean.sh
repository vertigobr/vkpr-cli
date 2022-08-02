#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Digital Ocean Credential validators
# -----------------------------------------------------------------------------

validateDigitalOceanApiToken() {
  if [[ "$1" =~ ^([a-z]+_v1_[A-Za-z0-9]{64})$ ]]; then
    return
    else
    error "Invalid Digital Ocean API Token, fix the credential with the command $(bold "rit set credential")."
    exit
  fi
}
