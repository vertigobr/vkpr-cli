#!/usr/bin/env bash

setproviderrun() {


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
  ### CRIIANDO REPOSITORIO ###
  githubCreateRepo "${DOMAIN}_site_s3" "$GITHUB_TOKEN" 

  ### CONFIGURANDO SECRECTS ####
  VAR_PROJECT_NAME="${GITHUB_USERNAME}/${CLUSTER_NAME}"
  
  PUBLIC_KEY=$(githubActionsGetPublicKey "$VAR_PROJECT_NAME" "$GITHUB_USERNAME" "$GITHUB_TOKEN")
  githubActionsCreateUpdateSecret "$VAR_PROJECT_NAME" "AWS_ACCESS_KEY" "$AWS_ACCESS_KEY" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
  githubActionsCreateUpdateSecret "$VAR_PROJECT_NAME" "AWS_SECRET_KEY" "$AWS_SECRET_KEY" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
  githubActionsCreateUpdateSecret "$VAR_PROJECT_NAME" "AWS_REGION" "$AWS_REGION" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"


  cd "$VKPR_HOME" || exit
  git clone https://github.com/vertigobr/aws_site_s3.git
  cd aws_site_s3
  rm -rf .git
  git init 
  git remote add origin https://github.com/${GITHUB_USERNAME}/${DOMAIN}_site_s3.git

######### YQ INSERT ###########
  $VKPR_YQ -i ".domain =\"${bucket}\"" "$VKPR_HOME"/aws_site_s3/config/defaults.yml

####### HABILITANDO CLOUDFRONT ####

  if [ $CLOUDFRONT == true ]; then
  printf "module \"site\" { \n    souce = \"./cloudfront \" \n     domain = local.config.domain \n   \n} " >> main.tf 
  cat  main .tf
  fi
  ### CONFIGURADO BACKEND S3
  if [ $TERRAFORM_STATE == "s3" ]; then
  printf "terraform { \n  backend \"s3\" { \n    bucket = \"${BUCKET_TERRAFORM}\" \n    key    = \"${BUCKET_TERRAFORM}.tfstate\" \n    region = \"${AWS_REGION}\" \n  }\n}" > backend.tf
  cat backend.tf
  fi
  cat "$VKPR_HOME"/aws_site_s3/config/defaults.yml
  mergeVkprValuesExtraArgs "aws_site_s3" "$VKPR_HOME"/aws_site_s3/"$VKPR_HOME"/aws_site_s3/config/defaults.yml
# git checkout -b "$VKPR_ENV_EKS_CLUSTER_NAME"
  git add .
  git commit -am "[VKPR] Initial configuration defaults.yml"
  git push --set-upstream origin master 
  cd - > /dev/null || exit
  rm -rf "$VKPR_HOME"/aws_site_s3

} 

