#!/usr/bin/env bash
runFormula() {
  installAWS
  setCredentials
  formulaInputs
  validateInputs

  info "Create db instance..."
  $VKPR_AWS rds create-db-instance \
    --db-instance-identifier "$VKPR_ENV_RDS_INSTANCE_NAME" \
    --db-instance-class "$VKPR_ENV_RDS_INSTANCE_TYPE" \
    --db-name "$VKPR_ENV_RDS_DB_NAME" \
    --engine postgres \
    --master-username "$VKPR_ENV_RDS_DB_USER" \
    --master-user-password "$VKPR_ENV_RDS_DB_PASSWORD" \
    --allocated-storage 20 1> /dev/null && boldNotice "Database created"

}

startInfos() {
  bold "=============================="
  boldInfo "VKPR AWS RDS provisioning routine"
  boldNotice " Instance Name: $VKPR_ENV_RDS_INSTANCE_NAME"
  boldNotice " Instance Type: $VKPR_ENV_RDS_INSTANCE_TYPE"
  boldNotice " Database Name: $VKPR_ENV_RDS_DB_NAME"
  boldNotice " Database User: $VKPR_ENV_RDS_DB_USER"
  boldNotice " Database Password: $VKPR_ENV_RDS_DB_PASSWORD"
  bold "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "$INSTANCE_NAME" "rds-sample" "aws.rds.instanceName" "RDS_INSTANCE_NAME"
  checkGlobalConfig "$INSTANCE_TYPE" "db.t3.micro" "aws.rds.instanceType" "RDS_INSTANCE_TYPE"
  checkGlobalConfig "$DBNAME" "vkprDb" "aws.rds.dbName" "RDS_DB_NAME"
  checkGlobalConfig "$DBUSER" "vkprUser" "aws.rds.dbUser" "RDS_DB_USER"
  checkGlobalConfig "$DBPASSWORD" "vkpr1234" "aws.rds.dbPassword" "RDS_DB_PASSWORD"
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
  validateAwsRdsInstanceType "$VKPR_ENV_RDS_INSTANCE_TYPE"
  validateAwsRdsDbName "$VKPR_ENV_RDS_DB_NAME"
  validateAwsRdsDbUser "$VKPR_ENV_RDS_DB_USER"
  validateAwsRdsDbPwd "$VKPR_ENV_RDS_DB_PASSWORD"
}
