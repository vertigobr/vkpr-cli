#!/usr/bin/env bash

formulaInputs() {
  # App values
  checkGlobalConfig "$CLUSTER_NAME" "eks-sample" "aws.eks.clusterName" "EKS_CLUSTER_NAME"
  checkGlobalConfig "$K8S_VERSION" "1.23" "aws.eks.version" "EKS_VERSION"
  checkGlobalConfig "$CLUSTER_NODE_INSTANCE_TYPE.$CLUSTER_NODE_INSTANCE_SIZE" "t3.small" "aws.eks.nodes.instanceType" "EKS_NODES_INSTANCE_TYPE"
  checkGlobalConfig "$CLUSTER_SIZE" "1" "aws.eks.nodes.quantitySize" "EKS_NODES_QUANTITY_SIZE"
  checkGlobalConfig "$CAPACITY_TYPE" "on_demand" "aws.eks.nodes.capacityType" "EKS_NODES_CAPACITY_TYPE"
  checkGlobalConfig "$TERRAFORM_STATE" "gitlab" "aws.eks.terraformState" "EKS_TERRAFORM_STATE"
  checkGlobalConfig "AL2_x86_64" "AL2_x86_64" "aws.eks.amiType" "EKS_AMI_TYPE"
}

setCredentials() {
  AWS_ACCESS_KEY="$($VKPR_JQ -r '.credential.accesskeyid' $VKPR_CREDENTIAL/aws)"
  AWS_SECRET_KEY="$($VKPR_JQ -r '.credential.secretaccesskey' $VKPR_CREDENTIAL/aws)"
  AWS_REGION="$($VKPR_JQ -r '.credential.region' $VKPR_CREDENTIAL/aws)"

  GITLAB_USERNAME="$($VKPR_JQ -r '.credential.username' $VKPR_CREDENTIAL/gitlab)"
  GITLAB_TOKEN="$($VKPR_JQ -r '.credential.token' $VKPR_CREDENTIAL/gitlab)"
  GITLAB_URL="$($VKPR_JQ -r '.credential.url' $VKPR_CREDENTIAL/gitlab)"

  GITHUB_USERNAME="$($VKPR_JQ -r '.credential.username' $VKPR_CREDENTIAL/github)"
  GITHUB_TOKEN="$($VKPR_JQ -r '.credential.token' $VKPR_CREDENTIAL/github)"

  S3_BUCKET="$($VKPR_JQ -r '.credential.bucket' $VKPR_CREDENTIAL/s3)"
  S3_KEY="$($VKPR_JQ -r '.credential.key' $VKPR_CREDENTIAL/s3)"
}

validateInputs() {
  validateAwsSecretKey "$AWS_SECRET_KEY"
  validateAwsAccessKey "$AWS_ACCESS_KEY"
  validateAwsRegion "$AWS_REGION"
  validateGitlabUsername "$GITLAB_USERNAME"
  [[ "$VKPR_ENV_EKS_TERRAFORM_STATE" == "terraform-cloud" ]] && validateTFCloudToken "$TERRAFORMCLOUD_API_TOKEN"

  validateEksClusterName "$VKPR_ENV_EKS_CLUSTER_NAME"
  validateEksVersion "$VKPR_ENV_EKS_VERSION"
  validateEksNodeInstanceType "$VKPR_ENV_EKS_NODES_INSTANCE_TYPE"

  validateEksClusterSize "$VKPR_ENV_EKS_NODES_QUANTITY_SIZE"
  validateEksCapacityType "$VKPR_ENV_EKS_NODES_CAPACITY_TYPE"
  validateEksStoreTfState "$VKPR_ENV_EKS_TERRAFORM_STATE"
}
