#!/bin/bash
runFormula() {

  validateAwsSecretKey "$AWS_SECRET_KEY"
  validateAwsAccessKey "$AWS_ACCESS_KEY"
  validateAwsRegion "$AWS_REGION"

  aws rds create-db-instance \
    --db-instance-identifier "$RDS_INSTANCE_NAME" \
    --db-instance-class "$RDS_INSTANCE_TYPE" \
    --engine postgres \
    --master-username "$DBUSER" \
    --master-user-password "$DBPASSWORD" \
    --allocated-storage 20 1> /dev/null && echo "Database created"
    
}