#!/usr/bin/env bash


runFormula() {
  setCredentials
  formulaInputs
  validateInputs

  info "Creating db snapshot..."
  $VKPR_AWS rds create-db-snapshot \
    --db-instance-identifier "$VKPR_ENV_RDS_INSTANCE_NAME" \
    --db-snapshot-identifier mydbsnapshot  1> /dev/null && boldNotice "Snapshot created"
}

formulaInputs() {
  # App values
  checkGlobalConfig "$INSTANCE_NAME" "rds-sample" "aws.rds.instanceName" "RDS_INSTANCE_NAME"
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
  # App values
  validateAwsRdsInstanceName "$VKPR_ENV_RDS_INSTANCE_NAME"
}
