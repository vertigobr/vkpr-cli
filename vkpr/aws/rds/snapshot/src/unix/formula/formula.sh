#!/bin/bash


runFormula() {
  setCredentials
  validateInputs

  info "Creating db snapshot..."
  aws rds create-db-snapshot \
    --db-instance-identifier "$RDS_INSTANCE_NAME" \
    --db-snapshot-identifier mydbsnapshot  1> /dev/null && boldNotice "Snapshot created"
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