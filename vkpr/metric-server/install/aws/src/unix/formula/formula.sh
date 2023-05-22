#!/usr/bin/env bash

runFormula() {
  local VKPR_CERT_MANAGER_VALUES VKPR_ISSUER_VALUES YQ_VALUES YQ_ISSUER_VALUES HELM_ARGS;
  setCredentials
  validateInputs

  startInfos
  settingCertManager
  if [[ $DRY_RUN == false ]]; then
    installApplication 
  fi
  applicationdry
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR metric-server Install AWS Routine"
  bold "=============================="
}


setCredentials() {
  AWS_REGION=$($VKPR_JQ -r .credential.region "$VKPR_CREDENTIAL"/aws)
  AWS_ACCESS_KEY=$($VKPR_JQ -r .credential.accesskeyid "$VKPR_CREDENTIAL"/aws)
  AWS_SECRET_KEY=$($VKPR_JQ -r .credential.secretaccesskey "$VKPR_CREDENTIAL"/aws)
}

validateInputs() {
  validateAwsAccessKey "$AWS_ACCESS_KEY"
  validateAwsSecretKey "$AWS_SECRET_KEY"
  validateAwsRegion "$AWS_REGION"
}

installApplication () {
  info "Installing metric-server CRDS beforehand..."
  $VKPR_KUBECTL apply -f "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
}

applicationdry () {
  info "Installing metric-server CRDS beforehand..."
  $VKPR_KUBECTL apply -f "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml" --dry-run
}