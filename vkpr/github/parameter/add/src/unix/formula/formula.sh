#!/usr/bin/env bash

runFormula() {
  info "In case of a module error with pynacl, execute the installation: pip install pynacl."
  info "Creating new secret ${PARAMETER_NAME}"
  setCredentials
 # validateInputs

  #getting public key to encrypt secret value
  PUBLIC_KEY=$(githubActionsGetPublicKey "$PROJECT_NAME" "$GITHUB_USERNAME" "$GITHUB_TOKEN")

  #calling function to create or update secret
  githubActionsCreateUpdateSecret "$PROJECT_NAME" "$SECRET_NAME" "$SECRET_VALUE" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
}

setCredentials() {
  GITHUB_TOKEN=$($VKPR_JQ -r .credential.token "$VKPR_CREDENTIAL"/github)
  GITHUB_USERNAME=$($VKPR_JQ -r .credential.username "$VKPR_CREDENTIAL"/github)

}

validateInputs(){
 validateGithubToken "$GITHUB_TOKEN"
 validateGithubUsername "$GITHUB_USERNAME"
}
