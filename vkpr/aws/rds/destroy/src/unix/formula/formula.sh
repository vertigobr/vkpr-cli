#!/bin/bash

runFormula() {
  aws rds delete-db-instance \
    --db-instance-identifier $RDS_INSTANCE_NAME \
    --skip-final-snapshot 1> /dev/null && echo "Database destroyed"
}