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
  ### CRIIANDO REPOSITORIO ###
  githubCreateRepo "${CLUSTER_NAME}" "$GITHUB_TOKEN" 

  ### CONFIGURANDO SECRECTS ####
  VAR_PROJECT_NAME="${GITHUB_USERNAME}/${CLUSTER_NAME}"
  
  PUBLIC_KEY=$(githubActionsGetPublicKey "$VAR_PROJECT_NAME" "$GITHUB_USERNAME" "$GITHUB_TOKEN")
  githubActionsCreateUpdateSecret "$VAR_PROJECT_NAME" "AWS_ACCESS_KEY" "$AWS_ACCESS_KEY" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
  githubActionsCreateUpdateSecret "$VAR_PROJECT_NAME" "AWS_SECRET_KEY" "$AWS_SECRET_KEY" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
  githubActionsCreateUpdateSecret "$VAR_PROJECT_NAME" "AWS_REGION" "$AWS_REGION" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
  githubActionsCreateUpdateSecret "$VAR_PROJECT_NAME" "INFRACOST_API_KEY" "$INFRACOST_API_KEY" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
  

  cd "$VKPR_HOME" || exit
  git clone https://github.com/vertigobr/aws-eks.git
  cd aws-eks 
  rm -rf .git
  git init 
  git remote add origin https://github.com/${GITHUB_USERNAME}/${CLUSTER_NAME}.git

######### YQ INSERT ###########
  $VKPR_YQ eval -i "del(.node_groups) |
    .cluster_name = \"${CLUSTER_NAME}\" |
    .cluster_version = \"${K8S_VERSION}\" |
    .node_groups.${CLUSTER_NAME}.desired_capacity = \"${CLUSTER_SIZE}\" |
    .node_groups.${CLUSTER_NAME}.max_capacity = \"$(( ${CLUSTER_SIZE} + 2 ))\" |
    .node_groups.${CLUSTER_NAME}.min_capacity = \"${CLUSTER_SIZE}\" |
    .node_groups.${CLUSTER_NAME}.ami_type = \"AL2_x86_64\" |
    .node_groups.${CLUSTER_NAME}.instance_types[0] = \"${CLUSTER_NODE_INSTANCE_TYPE}.${CLUSTER_NODE_INSTANCE_SIZE}\" |
    .node_groups.${CLUSTER_NAME}.capacity_type = \"${CAPACITY_TYPE^^}\" 
  " "$VKPR_HOME"/aws-eks/config/defaults.yml

  ########### BugFix AWS REGION AZ ###########
  case $AWS_REGION in
    us-east-1)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"us-east-1a\",\"us-east-1b\",\"us-east-1c\"]" "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    us-east-2)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"us-east-2a\",\"us-east-2b\",\"us-east-2c\"]" "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    us-west-1)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"us-west-1a\",\"us-west-1b\",\"us-west-1c\"]" "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    us-west-2)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"us-west-2a\",\"us-west-2b\",\"us-west-2c\"]"  "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    af-south-1)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"af-south-1a\",\"af-south-1b\",\"af-south-1c\"]" "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    ap-east-1)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"ap-east-1a\",\"ap-east-1b\",\"ap-east-1c\"]"  "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    ap-south-2)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"ap-south-2a\",\"ap-south-2b\",\"ap-south-2c\"]" "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    ap-southeast-3)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"ap-southeast-3a\",\"ap-southeast-3b\",\"ap-southeast-3c\"]"  "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    ap-south-1)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"ap-south-1a\",\"ap-south-1b\",\"ap-south-1c\"]" "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    ap-northeast-3)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"ap-northeast-3a\",\"ap-northeast-3b\",\"ap-northeast-3c\"]" "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    ap-northeast-2)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"ap-northeast-2a\",\"ap-northeast-2b\",\"ap-northeast-2c\"]"  "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    ap-northeast-1)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"ap-northeast-1a\",\"ap-northeast-1b\",\"ap-northeast-1c\"]" "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    ap-southeast-2)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"ap-southeast-2a\",\"ap-southeast-2b\",\"ap-southeast-2c\"]"  "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    ap-southeast-1)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"ap-southeast-1a\",\"ap-southeast-1b\",\"ap-southeast-1c\"]"  "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    ca-central-1)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"ca-central-1a\",\"ca-central-1b\",\"ca-central-1c\"]" "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    eu-central-1)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"eu-central-1a\",\"eu-central-1b\",\"eu-central-1c\"]" "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    eu-west-1)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"eu-west-1a\",\"eu-west-1b\",\"eu-west-1c\"]" "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    eu-west-2)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"eu-west-2a\",\"eu-west-2b\",\"eu-west-2c\"]" "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    eu-south-1)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"eu-south-1a\",\"eu-south-1b\",\"eu-south-1c\"]" "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    eu-west-3)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"eu-west-3a\",\"eu-west-3b\",\"eu-west-3c\"]" "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    eu-south-2)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"eu-south-2a\",\"eu-south-2b\",\"eu-south-2c\"]" "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    eu-north-1)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"eu-north-1a\",\"eu-north-1b\",\"eu-north-1c\"]" "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    eu-central-2)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"eu-central-2a\",\"eu-central-2b\",\"eu-central-2c\"]" "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    me-south-1)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"me-south-1a\",\"me-south-1b\",\"me-south-1c\"]" "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    me-central-1)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"me-central-1a\",\"me-central-1b\",\"me-central-1c\"]" "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
    sa-east-1)
    sed -i "/aws_availability_zones/c aws_availability_zones: [\"sa-east-1a\",\"sa-east-1b\",\"sa-east-1c\"]" "$VKPR_HOME"/aws-eks/config/defaults.yml
    ;;
  esac

    .node_groups.${CLUSTER_NAME}.capacity_type = \"${CAPACITY_TYPE^^}\"
  " config/defaults.yml"

  ### CONFIGURADO BACKEND S3
  if [ $TERRAFORM_STATE == "s3" ]; then
  printf "terraform { \n  backend \"s3\" { \n    bucket = \"${BUCKET_TERRAFORM}\" \n    key    = \" vkpr/${CLUSTER_NAME}.tfstate \" \n    region = \"${AWS_REGION}\" \n  }\n}" > backend.tf
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

