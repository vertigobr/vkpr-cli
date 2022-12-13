#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Github Credential validators
# -----------------------------------------------------------------------------

validateGithubToken() {
  if [[ "$1" =~ ^([A-Za-z0-9_]{40})$ ]]; then
    return
  else
    error "The value used for GITHUB_TOKEN \"$1\" is invalid: GITHUB_TOKEN must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'Aa1Bb2Cc3Dd4Ee5Ff6Gg7Hh8Ii9Jj10Kk11Ll12M', regex used for validation is ^([A-Za-z0-9-]{40})$."
    exit
  fi
}

validateGithubUsername() {
  if [[ "$1" =~ ^([A-Za-z0-9-]+)$ ]]; then
    return
  else
    error "The value used for GITHUB_USERNAME \"$1\" is invalid: GITHUB_USERNAME must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'github', regex used for validation is ^([A-Za-z0-9-]+)$."
    exit
  fi
}
