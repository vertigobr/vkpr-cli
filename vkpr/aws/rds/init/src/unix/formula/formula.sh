#!/bin/bash
runFormula() {
  setCredentials
  validateInputs

  info "Create db instance..."
  $VKPR_AWS rds create-db-instance \
    --db-instance-identifier "$RDS_INSTANCE_NAME" \
    --db-instance-class "$RDS_INSTANCE_TYPE" \
    --engine postgres \
    --master-username "$DBUSER" \
    --master-user-password "$DBPASSWORD" \
    --allocated-storage 20 1> /dev/null && boldNotice "Database created"
    
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