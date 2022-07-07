#!/bin/bash

runFormula() {
  setCredentials
  validateInputs

  info "Destroying db instance..."
  aws rds delete-db-instance \
    --db-instance-identifier "$RDS_INSTANCE_NAME" \
    --skip-final-snapshot 1> /dev/null && boldNotice "Database destroyed"
}

setCredentials() {
  AWS_ACCESS_KEY="$($VKPR_JQ -r '.credential.accesskeyid' $VKPR_CREDENTIAL/aws)"
  AWS_SECRET_KEY="$($VKPR_JQ -r '.credential.secretaccesskey' $VKPR_CREDENTIAL/aws)"
  AWS_REGION="$($VKPR_JQ -r '.credential.region' $VKPR_CREDENTIAL/aws)"
}

validateInputs() {
  validateAwsSecretKey "$AWS_SECRET_KEY"
  validateAwsAccessKey "$AWS_ACCESS_KEY"
  validateAwsRegion "$AWS_REGION"
}