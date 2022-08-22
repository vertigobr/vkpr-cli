#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Terraform Cloud Credential validators
# -----------------------------------------------------------------------------

validateTFCloudToken() {
  if [[ "$1" =~ ^([A-Za-z0-9]{14})\.(atlasv1)\.([A-Za-z0-9]{67})$ ]]; then
    return
  else
    error "Invalid Terraform API Token, fix the credential with the command $(bold "rit set credential")."
    exit
  fi
}
