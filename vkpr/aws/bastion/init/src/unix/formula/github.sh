#!/usr/bin/env bash

setproviderrun() {

formulaInputs() {
  # App values
  checkGlobalConfig "$CLUSTER_NAME" "eks-sample" "aws.eks.clusterName" "EKS_CLUSTER_NAME"
  checkGlobalConfig "$K8S_VERSION" "1.23" "aws.eks.version" "EKS_VERSION"
  checkGlobalConfig "$CLUSTER_NODE_INSTANCE_TYPE.$CLUSTER_NODE_INSTANCE_SIZE" "t3.small" "aws.eks.nodes.instanceType" "EKS_NODES_INSTANCE_TYPE"
  checkGlobalConfig "$CLUSTER_SIZE" "1" "aws.eks.nodes.quantitySize" "EKS_NODES_QUANTITY_SIZE"
  checkGlobalConfig "$CAPACITY_TYPE" "on_demand" "aws.eks.nodes.capacityType" "EKS_NODES_CAPACITY_TYPE"
  checkGlobalConfig "$TERRAFORM_STATE" "github" "aws.eks.terraformState" "EKS_TERRAFORM_STATE"
}

setCredentials() {
  AWS_ACCESS_KEY="$($VKPR_JQ -r '.credential.accesskeyid' $VKPR_CREDENTIAL/aws)"
  AWS_SECRET_KEY="$($VKPR_JQ -r '.credential.secretaccesskey' $VKPR_CREDENTIAL/aws)"
  AWS_REGION="$($VKPR_JQ -r '.credential.region' $VKPR_CREDENTIAL/aws)"
  GITHUB_TOKEN=$($VKPR_JQ -r .credential.token "$VKPR_CREDENTIAL"/github)
  GITHUB_USERNAME=$($VKPR_JQ -r .credential.username "$VKPR_CREDENTIAL"/github)
}

validateInputs() {
  validateAwsSecretKey "$AWS_SECRET_KEY"
  validateAwsAccessKey "$AWS_ACCESS_KEY"
  validateAwsRegion "$AWS_REGION"
  validateGITHUBUsername "$GITHUB_USERNAME"
  validateGITHUBToken "$GITHUB_TOKEN"
  #[[ "$VKPR_ENV_EKS_TERRAFORM_STATE" == "terraform-cloud" ]] && validateTFCloudToken "$TERRAFORMCLOUD_API_TOKEN"

  validateEksClusterName "$VKPR_ENV_EKS_CLUSTER_NAME"
  validateEksVersion "$VKPR_ENV_EKS_VERSION"
  validateEksNodeInstanceType "$VKPR_ENV_EKS_NODES_INSTANCE_TYPE"

  validateEksClusterSize "$VKPR_ENV_EKS_NODES_QUANTITY_SIZE"
  validateEksCapacityType "$VKPR_ENV_EKS_NODES_CAPACITY_TYPE"
  #validateEksStoreTfState "$VKPR_ENV_EKS_TERRAFORM_STATE"
}

setVariablesGHUB() {
  [[ $PROJECT_LOCATION == "groups" ]] && PROJECT_IDENTIFIER=$PROJECT_ID || PROJECT_IDENTIFIER=$PROJECT_ENCODED
  [[ "$VKPR_ENV_EKS_TERRAFORM_STATE" == "terraform-cloud" ]] && createOrUpdateVariable "$PROJECT_IDENTIFIER" "TF_CLOUD_TOKEN" "$TF_CLOUD_TOKEN" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITHUB_TOKEN"
  createOrUpdateVariable "$PROJECT_IDENTIFIER" "AWS_ACCESS_KEY" "$AWS_ACCESS_KEY" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITHUB_TOKEN"
  createOrUpdateVariable "$PROJECT_IDENTIFIER" "AWS_SECRET_KEY" "$AWS_SECRET_KEY" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITHUB_TOKEN"
  createOrUpdateVariable "$PROJECT_IDENTIFIER" "AWS_REGION" "$AWS_REGION" "no" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITHUB_TOKEN"
  createOrUpdateVariable "$PROJECT_IDENTIFIER" "CI_GITHUB_TOKEN" "$GITHUB_TOKEN" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITHUB_TOKEN"
}
  ### CRIANDO REPOSITORIO ###
  githubCreateRepo "${PROJECTNAME}" "$GITHUB_TOKEN" 

  ### CONFIGURANDO SECRECTS ####
  VAR_PROJECT_NAME="${GITHUB_USERNAME}/${PROJECTNAME}"
  
  PUBLIC_KEY=$(githubActionsGetPublicKey "$VAR_PROJECT_NAME" "$GITHUB_USERNAME" "$GITHUB_TOKEN")
  githubActionsCreateUpdateSecret "$VAR_PROJECT_NAME" "AWS_ACCESS_KEY" "$AWS_ACCESS_KEY" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
  githubActionsCreateUpdateSecret "$VAR_PROJECT_NAME" "AWS_SECRET_KEY" "$AWS_SECRET_KEY" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
  githubActionsCreateUpdateSecret "$VAR_PROJECT_NAME" "AWS_REGION" "$AWS_REGION" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"


  cd "$VKPR_HOME" || exit
  git clone https://github.com/vertigobr/aws-bastion.git
  cd aws-bastion 
  rm -rf .git
  git init 
  git remote add origin https://github.com/${GITHUB_USERNAME}/${PROJECTNAME}.git

######### YQ INSERT ###########
  $VKPR_YQ -i ".bastion.image = \"${IMAGE}\" |
    .bastion.keyname = \"${KEYNAME}\" |
    .bastion.host= \"${INSTANCE_TYPE}.${INSTANCE_SIZE}\" " "$VKPR_HOME"/aws-bastion/config/defaults.yml
   cat "$VKPR_HOME"/aws-bastion/config/defaults.yml

  ### CONFIGURADO BACKEND S3
  if [ $TERRAFORM_STATE == "s3" ]; then
  printf "terraform { \n  backend \"s3\" { \n    bucket = \"${BUCKET_TERRAFORM}\" \n    key    = \"${BUCKET_TERRAFORM}.tfstate\" \n    region = \"${AWS_REGION}\" \n  }\n}" > backend.tf
  cat backend.tf
  fi
  #cat "$VKPR_HOME"/aws-bastion/config/defaults.yml
  mergeVkprValuesExtraArgs "aws.eks" "$VKPR_HOME"/aws-bastion/"$VKPR_HOME"/aws-bastion/config/defaults.yml
# git checkout -b "$VKPR_ENV_EKS_CLUSTER_NAME"
  git add .
  git commit -am "[VKPR] Initial configuration defaults.yml"
  git push --set-upstream origin master 
  cd - > /dev/null || exit
  rm -rf "$VKPR_HOME"/aws-eks

} 

