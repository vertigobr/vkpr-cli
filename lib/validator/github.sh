#!/bin/bash

# -----------------------------------------------------------------------------
# Github Credential validators
# -----------------------------------------------------------------------------

validateGithubToken() {
  if [[ "$1" =~ ^([A-Za-z0-9-]{40})$ ]]; then
    return
  else
    error "Invalid Github Access Token, fix the credential with the command $(bold "rit set credential")."
    exit
  fi
}

validateGithubUsername() {
  if [[ "$1" =~ ^([A-Za-z0-9-]+)$ ]]; then
    return
  else
    error "Invalid Github Username, fix the credential with the command $(bold "rit set credential")."
    exit
  fi
}