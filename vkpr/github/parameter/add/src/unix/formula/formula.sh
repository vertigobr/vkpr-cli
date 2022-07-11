#!/bin/bash

runFormula() {
  info "Creating new secret ${PARAMETER_NAME}"

  #getting public key to encrypt secret value
  PUBLIC_KEY=$(githubActionsGetPublicKey "$PROJECT_NAME" "$GITHUB_USERNAME" "$GITHUB_TOKEN")

  #calling function to create or update secret
  githubActionsCreateUpdateSecret "$PROJECT_NAME" "$SECRET_NAME" "$SECRET_VALUE" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
}
