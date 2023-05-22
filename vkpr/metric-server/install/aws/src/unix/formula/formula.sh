#!/usr/bin/env bash

runFormula() {
  setCredentials
  [ $DRY_RUN == false ] 
  validateInputs
  [ $DRY_RUN == false ]
  startInfos
  [ $DRY_RUN == false ]
  installApplication 
}
startInfos() {
  bold "=============================="
  boldInfo "VKPR Metric-Server Install AWS Routine"
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
    info "Installing Metric-Server ..."
    $VKPR_KUBECTL apply -f "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
}




