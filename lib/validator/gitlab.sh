#!/bin/bash

# -----------------------------------------------------------------------------
# Gitlab Credential validators
# -----------------------------------------------------------------------------

validateGitlabToken() {
  if [[ "$1" =~ ^([A-Za-z0-9-]{26})$ ]]; then
    return
    else
    error "Invalid Gitlab Access Token, fix the credential with the command $(bold "rit set credential")."
    exit
  fi
}

validateGitlabUsername() {
  if [[ "$1" =~ ^([A-Za-z0-9-]+)$ ]]; then
    return
    else
    error "Invalid Gitlab Username, fix the credential with the command $(bold "rit set credential")."
    exit
  fi
}