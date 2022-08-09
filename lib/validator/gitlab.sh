#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Gitlab Credential validators
# -----------------------------------------------------------------------------

validateGitlabToken() {
  if [[ "$1" =~ ^([A-Za-z0-9-]{26})$ ]]; then
    return
    else
    error "The value used for GITLAB_TOKEN \"$1\" is invalid: GITLAB_TOKEN must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'Aa1Bb2Cc3Dd4Ee5Ff6Gg7Hh8Ii', regex used for validation is ^([A-Za-z0-9-]{26})$."
    exit
  fi
}

validateGitlabUsername() {
  if [[ "$1" =~ ^([A-Za-z0-9-]+)$ ]]; then
    return
    else
    error "The value used for GITLAB_USERNAME \"$1\" is invalid: GITLAB_USERNAME must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'gitlab', regex used for validation is ^([A-Za-z0-9-]+)$."
    exit
  fi
}
