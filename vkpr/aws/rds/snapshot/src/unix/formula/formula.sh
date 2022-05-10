#!/bin/bash


runFormula() {

  validateAwsSecretKey "$AWS_SECRET_KEY"
  validateAwsAccessKey "$AWS_ACCESS_KEY"
  validateAwsRegion "$AWS_REGION"
  
  aws rds create-db-snapshot \
    --db-instance-identifier "$RDS_INSTANCE_NAME" \
    --db-snapshot-identifier mydbsnapshot  1> /dev/null && echo "Snapshot created"
}
