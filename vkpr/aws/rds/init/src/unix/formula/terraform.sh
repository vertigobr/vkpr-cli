#!/usr/bin/env bash

setproviderrun() {

setCredentials() {
  AWS_ACCESS_KEY="$($VKPR_JQ -r '.credential.accesskeyid' $VKPR_CREDENTIAL/aws)"
  AWS_SECRET_KEY="$($VKPR_JQ -r '.credential.secretaccesskey' $VKPR_CREDENTIAL/aws)"
  AWS_REGION="$($VKPR_JQ -r '.credential.region' $VKPR_CREDENTIAL/aws)"
  GITHUB_TOKEN=$($VKPR_JQ -r .credential.token "$VKPR_CREDENTIAL"/github)
  GITHUB_USERNAME=$($VKPR_JQ -r .credential.username "$VKPR_CREDENTIAL"/github)
}

setVariablesGHUB() {
  [[ $PROJECT_LOCATION == "groups" ]] && PROJECT_IDENTIFIER=$PROJECT_ID || PROJECT_IDENTIFIER=$PROJECT_ENCODED
  [[ "$VKPR_ENV_EKS_TERRAFORM_STATE" == "terraform-cloud" ]] && createOrUpdateVariable "$PROJECT_IDENTIFIER" "TF_CLOUD_TOKEN" "$TF_CLOUD_TOKEN" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITHUB_TOKEN"
  createOrUpdateVariable "$PROJECT_IDENTIFIER" "AWS_ACCESS_KEY" "$AWS_ACCESS_KEY" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITHUB_TOKEN"
  createOrUpdateVariable "$PROJECT_IDENTIFIER" "AWS_SECRET_KEY" "$AWS_SECRET_KEY" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITHUB_TOKEN"
  createOrUpdateVariable "$PROJECT_IDENTIFIER" "AWS_REGION" "$AWS_REGION" "no" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITHUB_TOKEN"
  createOrUpdateVariable "$PROJECT_IDENTIFIER" "CI_GITHUB_TOKEN" "$GITHUB_TOKEN" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITHUB_TOKEN"
}
  ### CRIIANDO REPOSITORIO ###
  githubCreateRepo "${CLUSTER_NAME}" "$GITHUB_TOKEN" 

  ### CONFIGURANDO SECRECTS ####
  VAR_PROJECT_NAME="${GITHUB_USERNAME}/${CLUSTER_NAME}"
  
  PUBLIC_KEY=$(githubActionsGetPublicKey "$VAR_PROJECT_NAME" "$GITHUB_USERNAME" "$GITHUB_TOKEN")
  githubActionsCreateUpdateSecret "$VAR_PROJECT_NAME" "AWS_ACCESS_KEY" "$AWS_ACCESS_KEY" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
  githubActionsCreateUpdateSecret "$VAR_PROJECT_NAME" "AWS_SECRET_KEY" "$AWS_SECRET_KEY" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
  githubActionsCreateUpdateSecret "$VAR_PROJECT_NAME" "AWS_REGION" "$AWS_REGION" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"


  cd "$VKPR_HOME" || exit
  git clone https://github.com/vertigobr/aws_rds.git
  cd aws-eks 
  rm -rf .git
  git init 
  git remote add origin https://github.com/${GITHUB_USERNAME}/${CLUSTER_NAME}.git

######### YQ INSERT ###########
  $VKPR_YQ -i ".allocated_storage = \"${CLUSTER_NAME}\" |
    .engine = \"${K8S_VERSION}\" |
    .engine_version = \"${CLUSTER_SIZE}\" |
    .instance_class = \"$(( ${CLUSTER_SIZE} + 2 ))\" |
    .name = \"${CLUSTER_SIZE}\" |
    .username = \"AL2_x86_64\" |
    .password = \"${CLUSTER_NODE_INSTANCE_TYPE}.${CLUSTER_NODE_INSTANCE_SIZE}\" |
    .skip_final_snapshot = \"${CAPACITY_TYPE^^}\" 
  " "$VKPR_HOME"/aws-eks/config/defaults.yml

  ### CONFIGURADO BACKEND S3
  if [ $TERRAFORM_STATE == "s3" ]; then
  printf "terraform { \n  backend \"s3\" { \n    bucket = \"${BUCKET_TERRAFORM}\" \n    key    = \"${BUCKET_TERRAFORM}.tfstate\" \n    region = \"${AWS_REGION}\" \n  }\n}" > backend.tf
  cat backend.tf
  fi
  cat "$VKPR_HOME"/aws-eks/config/defaults.yml
  mergeVkprValuesExtraArgs "aws.eks" "$VKPR_HOME"/aws-eks/"$VKPR_HOME"/aws-eks/config/defaults.yml
# git checkout -b "$VKPR_ENV_EKS_CLUSTER_NAME"
  git add .
  git commit -am "[VKPR] Initial configuration defaults.yml"
  git push --set-upstream origin master 
  cd - > /dev/null || exit
  rm -rf "$VKPR_HOME"/aws-eks

} 

