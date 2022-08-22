#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# AWS Credential validators
# -----------------------------------------------------------------------------

validateAwsSecretKey() {
  if [[ "$1" =~ ^([a-zA-Z0-9+/]{40})$ ]]; then
    return
  else
    error "The value used for AWS_SECRET_KEY \"$1\" is invalid:  the AWS_SECRET_KEY must consist of a lowercase, uppercase alphanumeric  characters, '-' or '.' (e.g. 'Aa1Bb2Cc3Dd4Ee5Ff6Gg7Hh8Ii9Jj10Kk11Ll12M', regex used for validation is '^([a-zA-Z0-9+/]{40})$')"
    exit
  fi
}

validateAwsAccessKey() {
  if [[ "$1" =~ ^([A-Z0-9]{20})$ ]]; then
    return
  else
    error "The value used for AWS_ACESS_KEY \"$1\" is invalid:  the AWS_ACESS_KEY must consist of a uppercase alphanumeric characters, '-' or '.' (e.g. 'Aa1Bb2Cc3Dd4Ee5Ff6Gg', regex used for validation is '^([A-Z0-9]{20})$')"
    exit
  fi
}

validateAwsRegion() {
  if [[ "$1" =~ ^([a-z]+-)([a-z]+-)[1-3]$ ]]; then
    return
  else
    error "The value used for AWS_REGION \"$1\" is invalid:  the AWS_REGION must consist of a lowercase alphanumeric  characters, '-' or '.' (e.g. 'us-east-1', regex used for validation is '^([a-z]+-)([a-z]+-)[1-3]$')"
    exit
  fi
}

# -----------------------------------------------------------------------------
# EKS CLuster Info validators
# -----------------------------------------------------------------------------

validateEksClusterName() {
  if [[ "$1" =~ ^([A-Za-z0-9-]+)$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_EKS_CLUSTER_NAME \"$1\" is invalid: VKPR_ENV_EKS_CLUSTER_NAME must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'eks-sample', regex used for validation is ^([A-Za-z0-9-]+)$)."
    exit
  fi
}

validateEksVersion() {
  if [[ "$1" =~ ^([0-9]{1}\.[0-9]{2})$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_EKS_VERSION \"$1\" is invalid: VKPR_ENV_EKS_VERSION must consist of number, (e.g. '1.21', regex used for validation is ^([0-9]{1}\.[0-9]{2})$."
    exit
  fi
}

validateEksNodeInstanceType() {
  if [[ "$1" =~ ^([a-z0-9]{2,}\.[a-z]{5,})$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_EKS_NODES_INSTANCE_TYPE \"$1\" is invalid: VKPR_ENV_EKS_NODES_INSTANCE_TYPE must consist of lowercase and alphanumeric characters, (e.g. 't3.small', regex used for validation is ^([a-z0-9]{2,}\.[a-z]{5,})$)."
    exit
  fi    
}

validateEksClusterSize() {
  if $(validateNumber $1); then
    return
  else
    error "The value used for VKPR_ENV_EKS_NODES_QUANTITY_SIZE \"$1\" is invalid: VKPR_ENV_EKS_NODES_QUANTITY_SIZE must consist of integer, (e.g. '1', regex used for validation is ^([0-9])$."
    exit
  fi
}

validateEksCapacityType() {
  if [[  "$1" =~ ^(on_demand|spot)$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_EKS_NODES_CAPACITY_TYPE \"$1\" is invalid: VKPR_ENV_EKS_NODES_CAPACITY_TYPE must consist of ON_DEMAND or SPOT value"
    exit
  fi
}

validateEksStoreTfState() {
  if [[ "$1"  =~ ^(gitlab|terraform-cloud)$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_EKS_TERRAFORM_STATE \"$1\" is invalid: VKPR_ENV_EKS_TERRAFORM_STATE must consist of gitlab or terraform-cloud value"
    exit
  fi 
}


# -----------------------------------------------------------------------------
# AWS Credential validators
# -----------------------------------------------------------------------------


validateAwsRdsInstanceName (){
  if [[ "$1" =~ ^([A-Za-z0-9-]+)$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_RDS_INSTANCE_NAME \"$1\" is invalid: VKPR_ENV_RDS_INSTANCE_NAME must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'rds-sample', regex used for validation is ^([A-Za-z0-9-]+)$)."
    exit
  fi
}

validateAwsRdsInstanceType (){
  if [[ "$1" =~ ^([a-z]{2}\.[a-z0-9]{2,}\.[a-z]{5,})$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_RDS_INSTANCE_TYPE \"$1\" is invalid: VKPR_ENV_RDS_INSTANCE_TYPE must consist of lowercase and alphanumeric characters, (e.g. 'db.t3.micro', regex used for validation is ^([a-z]{2}\.[a-z0-9]{2,}\.[a-z]{5,})$)."
    exit
  fi  

}

validateAwsRdsDbName (){
  if [[ "$1" =~ ^([A-Za-z0-9-]+)$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_RDS_DB_NAME \"$1\" is invalid: VKPR_ENV_RDS_DB_NAME must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'vkprDb', regex used for validation is ^([A-Za-z0-9-]+)$)."
    exit
  fi
}

validateAwsRdsDbUser (){
  if [[ "$1" =~ ^([A-Za-z0-9-]+)$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_RDS_DB_USER \"$1\" is invalid: VKPR_ENV_RDS_DB_USER must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'vkprUser', regex used for validation is ^([A-Za-z0-9-]+)$)."
    exit
  fi
}

validateAwsRdsDbPwd (){
  if $(validatePwd $1); then
    return
  else
    error "The value used for VKPR_ENV_RDS_DB_PASSWORD \"$1\" is invalid: VKPR_ENV_RDS_DB_PASSWORD must consist of lowercase, uppercase or alphanumeric characters, (e.g. 'vkpr123', regex used for validation is ^([A-Za-z0-9-]{7,})$')"
    exit
  fi
}
