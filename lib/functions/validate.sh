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
# Digital Ocean Credential validators
# -----------------------------------------------------------------------------

validateDigitalOceanApiToken() {
  if [[ "$1" =~ ^([a-z]+_v1_[A-Za-z0-9]{64})$ ]]; then
    return
    else
    error "Invalid Digital Ocean API Token, fix the credential with the command $(bold "rit set credential")."
    exit
  fi
}

# -----------------------------------------------------------------------------
# Azure Credential validators
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Gitlab Credential validators
# -----------------------------------------------------------------------------

validateGitlabToken() {
  if [[ "$1" =~ ^([A-Za-z0-9-]{26})$ ]]; then
    return
    else
    error "Invalid Gitlab Access Token, fix the credential with the command $(bold "rit set credential")."
    exit
  fi
}

validateGitlabUsername() {
  if [[ "$1" =~ ^([A-Za-z0-9-]+)$ ]]; then
    return
    else
    error "Invalid Gitlab Username, fix the credential with the command $(bold "rit set credential")."
    exit
  fi
}

# -----------------------------------------------------------------------------
# Terraform Cloud Credential validators
# -----------------------------------------------------------------------------

validateTFCloudToken() {
  if [[ "$1" =~ ^([A-Za-z0-9]{14})\.(atlasv1)\.([A-Za-z0-9]{67})$ ]]; then
    return
    else
    error "Invalid Terraform API Token, fix the credential with the command $(bold "rit set credential")."
    exit
  fi
}


# -----------------------------------------------------------------------------
# Misc Credential validators
# -----------------------------------------------------------------------------

validatePostgresqlPassword() {
  if [[ "$1" =~ ^([A-Za-z0-9-]{7,})$ ]]; then
    return
    else
    error "Week Postgresql Password, we recommend change the credential with the command $(bold "rit set credential")."
  fi
}

validateBool(){
  if [[  $(echo $1 | tr '[:upper:]' '[:lower:]') =~ ^true|false$ ]]; then
   return false
  else
    return true
    exit
  fi
}

validateWhoamiSecure(){
  if validateBool $1; then
    return
  else
    error "Specifies if the application will have HTTPS."
    exit
  fi
}

validateInfraTraefik(){
  if validateBool $1; then
    return
  else
    error "Enable Traefik by default in Cluster."
    exit
  fi
}

validateInfraHTTP(){
  echo $1
  if [[ "$1" =~ ^([0-9]{,4})$ ]]; then
    return
  else
    error "It was not possible to identify if the application will have HTTP."
    exit
  fi
}

validateInfraHTTPS(){
  if [[ "$1" =~ ^([0-9]{4})$ ]]; then
    return
  else
    error "It was not possible to identify if the application will have HTTPS."
    exit
  fi
}

validateInfraNodes(){
  if [[ "$1" =~ ^([0-9]{,1})$ ]]; then
    return
  else
    error "It was not possible to identify if the application will have Nodes."
    exit
  fi
}
# -----------------------------------------------------------------------------
# Binary validators
# -----------------------------------------------------------------------------

validateKubectlVersion() {
  if [[ ! -f $VKPR_KUBECTL ]] || [[ $($VKPR_KUBECTL version --short --client | awk -F " " '{print $3}') = "$VKPR_TOOLS_KUBECTL" ]]; then
    return
  else
    rm "$VKPR_KUBECTL"
  fi
}

validateHelmVersion() {
  if [[ ! -f $VKPR_HELM ]] || [[ $($VKPR_HELM version --short | awk -F "+" '{print $1}') = "$VKPR_TOOLS_HELM" ]]; then
    return
  else
    rm "$VKPR_HELM"
  fi
}

validateK3DVersion() {
  if [[ ! -f $VKPR_K3D ]] || [[ $($VKPR_K3D version | awk -F " " '{print $3}' | head -n1) = "$VKPR_TOOLS_K3D" ]]; then
    return
  else
    rm "$VKPR_K3D"
  fi
}

validateJQVersion() {
  if [[ ! -f $VKPR_JQ ]] || [[ $($VKPR_JQ --version) = "$VKPR_TOOLS_JQ" ]]; then
    return
  else
    rm "$VKPR_JQ"
  fi
}

validateYQVersion() {
  if [[ ! -f $VKPR_YQ ]] || [[ $($VKPR_YQ --version | awk -F " " '$4="v"$4 {print $4}') = "$VKPR_TOOLS_YQ" ]]; then
    return
  else
    rm "$VKPR_YQ"
  fi
}

validateK9SVersion() {
  if [[ ! -f $VKPR_K9S ]] || [[ $($VKPR_K9S version --short | awk -F " " '{print $2}' | head -n1) = "$VKPR_TOOLS_K9S" ]]; then
    return
  else
    rm "$VKPR_K9S"
  fi
}
# -----------------------------------------------------------------------------
# Kong Credential validators
# -----------------------------------------------------------------------------

validateBool(){
  if [[  $(echo $1 | tr '[:upper:]' '[:lower:]') =~ ^true|false$ ]]; then
   return
  else
    echo "error"
    exit
  fi
}

validateKongDomain() {
  if [[ "$1" =~ ^([A-Za-z0-9])$ ]]; then
    return
    else
    error "Please correctly enter the domain to be used "
    exit
  fi
}

validateKongHTTP() {
  if validateBool $1 | grep -q "error" ; then
      error "It was not possible to identify if the application will have HTTPS"
      exit
  else
    return
  fi
}

validateKongDeployment() {
  if [[ $(echo $1 | tr '[:upper:]' '[:lower:]') =~ ^(standard|hybrid|dbless)$ ]]; then
    return
    else
    error "It was not possible to identify the type of deployment of Kong"
    exit
  fi
}

validateKongEnterpriseLicense() {
  if validateBool $1 | grep -q "error"; then
      error "It was not possible to identify if the application will use enterprise license!"
      exit
    else
      return
  fi
}

validateKongEnterpriseLicensePath() {
  if [[ "$1" =~ ^(\/[^\/]+){0,2}\/?$ ]]; then
    return
  else
    error "Invalid path"
    exit
  fi
}

validateKongRBACPsw() {
  if [[ "$1" =~ ^([A-Za-z0-9-]{7,})$ ]]; then
    return
  else
    error "Invalid password"
    exit
  fi
}

validateHA(){
  if validateBool $1 | grep -q "error" ; then
      error "It was not possible to identify if the application will have High Availability "
      exit
  else
    return
  fi
}

# -----------------------------------------------------------------------------
# Cert Manager validators
# -----------------------------------------------------------------------------

validateCertManagerEmail() {
  if [[ "$1" =~ ^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-z]{2,}$ ]]; then
    return
  else
    error "Invalid email"
    exit
  fi
}

validateIssuerType(){
  if [[  $(echo $1 | tr '[:upper:]' '[:lower:]') =~ ^staging|production$ ]]; then
   return
  else
    error "It was not possible to identify what is the cluster issuer"
    exit
  fi
}

validateIssuerSolver(){
  if [[ "$1" =~ ^HTTP01|DNS01$ ]]; then
   return
  else
    error "It was not possible to identify what type of challenge you will use to issue the certificate"
    exit
  fi
}

validateCertManagerNamespace(){
  if [[ "$1" =~ ^cert-manager$ ]]; then
    return
  else
    error "Please correctly enter the Namespace to be used"
    exit
  fi
}

validateCertManagerIssueIngress(){
  if [[ "$1" =~ ^nginx$ ]]; then
   return
  else
    error "invalid value for cert-manager issue ingress"
    exit
  fi 
}