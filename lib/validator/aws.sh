#!/bin/bash

# -----------------------------------------------------------------------------
# AWS Credential validators
# -----------------------------------------------------------------------------

validateAwsSecretKey() {
  if [[ "$1" =~ ^([a-zA-Z0-9+/]{40})$ ]]; then
    return
  else
    error "Invalid AWS Secret Key, fix the credential with the command $(bold "rit set credential")."
    exit
  fi
}

validateAwsAccessKey() {
  if [[ "$1" =~ ^([A-Z0-9]{20})$ ]]; then
    return
  else
    error "Invalid AWS Access Key, fix the credential with the command $(bold "rit set credential")."
    exit
  fi
}

validateAwsRegion() {
  if [[ "$1" =~ ^([a-z]+-)([a-z]+-)[1-3]$ ]]; then
    return
  else
    error "Invalid AWS Region, fix the credential with the command $(bold "rit set credential")."
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
    error "Invalid EKS Cluster name."
    exit
  fi
}

validateEksVersion() {
  if [[ "$1" =~ ^(1.21|1.20|1.19|1.18|1.17)$ ]]; then
    return
  else
    error "Invalid EKS Cluster version."
    exit
  fi
}

validateEksNodeInstanceType() {
  if [[ "$1" =~ ^(t3.small|m5.large|m5.xlarge|t4g.small|m6g.large|m6g.xlarge)$ ]]; then
    return
  else
    error "Invalid EKS Node Instance type."
    exit
  fi    
}

validateEksClusterSize() {
  if $(validateNumber $1); then
    return
  else
    error "It was not possible to identify if the application will have Nodes."
    exit
  fi
}

validateEksCapacityType() {
  if [[  "$1" =~ ^(on_demand|spot)$ ]]; then
    return
  else
    error "It was not possible to identify the Node Group capacity type"
    exit
  fi
}

validateEksStoreTfState() {
  if [[ "$1"  =~ ^(gitlab|terraform-cloud)$ ]]; then
    return
  else
    error "It was not possible to identify where you want to store the TF state"
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
    error "Invalid RDS instance name."
    exit
  fi
}

validateAwsRdsInstanceType (){
  if [[ "$1" =~ ^(db.t3.micro|db.m5.large|db.m5.xlarge|db.t4g.micro|db.m6g.large|db.m6g.xlarge)$ ]]; then
    return
  else
    error "Invalid RDS Instance type."
    exit
  fi  

}

validateAwsRdsDbName (){
  if [[ "$1" =~ ^([A-Za-z0-9-]+)$ ]]; then
    return
  else
    error "Invalid RDS database name."
    exit
  fi
}

validateAwsRdsDbUser (){
  if [[ "$1" =~ ^([A-Za-z0-9-]+)$ ]]; then
    return
  else
    error "Invalid RDS database user name."
    exit
  fi
}

validateAwsRdsDbPwd (){
  if $(validatePwd $1); then
    return
  else
    error "Invalid RDS database user password ."
    exit
  fi
}
