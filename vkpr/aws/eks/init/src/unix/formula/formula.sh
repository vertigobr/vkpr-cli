#!/bin/bash

PROJECT_ID=$(rawUrlEncode "${GITLAB_USERNAME}/aws-eks")

runFormula() {
  checkGlobalConfig "$EKS_CLUSTER_NAME" "eks-sample" "aws.eks.clusterName" "EKS_CLUSTER_NAME"
  checkGlobalConfig "$EKS_K8S_VERSION" "1.21" "aws.eks.version" "EKS_K8S_VERSION"
  #checkGlobalConfig "$EKS_CLUSTER_NODE_INSTANCE_TYPE" "t3.small" "aws.eks.nodes.instaceType" "EKS_CLUSTER_NODE_INSTANCE_TYPE"
  checkGlobalConfig "$EKS_CLUSTER_SIZE" "1" "aws.eks.nodes.quantitySize" "EKS_CLUSTER_SIZE"
  checkGlobalConfig "$EKS_CAPACITY_TYPE" "ON_DEMAND" "aws.eks.nodes.capacityType" "EKS_CAPACITY_TYPE"

  validateAwsSecretKey "$AWS_SECRET_KEY"
  validateAwsAccessKey "$AWS_ACCESS_KEY"
  validateAwsRegion "$AWS_REGION"
  validateGitlabUsername "$GITLAB_USERNAME"
  validateGitlabToken "$GITLAB_TOKEN"
  [[ "$TERRAFORM_STATE" == "Terraform Cloud" ]] && validateTFCloudToken "$TERRAFORMCLOUD_API_TOKEN"

  #getting real instance type
  EKS_CLUSTER_NODE_INSTANCE_TYPE=${EKS_CLUSTER_NODE_INSTANCE_TYPE// ([^)]*)/}
  EKS_CLUSTER_NODE_INSTANCE_TYPE=${EKS_CLUSTER_NODE_INSTANCE_TYPE// /}


  local FORK_RESPONSE_CODE
  FORK_RESPONSE_CODE=$(curl -siX POST -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "https://gitlab.com/api/v4/projects/$(rawUrlEncode "vkpr/aws-eks")/fork" |\
    head -n 1 | awk -F' ' '{print $2}'
  )

  # echo "FORK_RESPONSE_CODE= $FORK_RESPONSE_CODE"
  if [ "$FORK_RESPONSE_CODE" == "409" ];then
    echoColor yellow "Project already forked"
  fi
  
  setVariablesGLAB

  createBranch "$PROJECT_ID" "$EKS_CLUSTER_NAME" "$GITLAB_TOKEN"

}

## Set all input into Gitlab environments
setVariablesGLAB() {
  [[ "$TERRAFORM_STATE" == "Terraform Cloud" ]] && createOrUpdateVariable "$PROJECT_ID" "TF_CLOUD_TOKEN" "$TF_CLOUD_TOKEN" "yes" "$EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
  createOrUpdateVariable "$PROJECT_ID" "AWS_ACCESS_KEY" "$AWS_ACCESS_KEY" "yes" "$EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
  createOrUpdateVariable "$PROJECT_ID" "AWS_SECRET_KEY" "$AWS_SECRET_KEY" "yes" "$EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
  createOrUpdateVariable "$PROJECT_ID" "AWS_REGION" "$AWS_REGION" "no" "$EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
  createOrUpdateVariable "$PROJECT_ID" "EKS_CLUSTER_NAME" "$EKS_CLUSTER_NAME" "no" "$EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
  createOrUpdateVariable "$PROJECT_ID" "EKS_CLUSTER_NODE_INSTANCE_TYPE" "$EKS_CLUSTER_NODE_INSTANCE_TYPE" "no" "$EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
  createOrUpdateVariable "$PROJECT_ID" "EKS_K8S_VERSION" "$EKS_K8S_VERSION" "no" "$EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
  createOrUpdateVariable "$PROJECT_ID" "EKS_CLUSTER_SIZE" "$EKS_CLUSTER_SIZE" "no" "$EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
  createOrUpdateVariable "$PROJECT_ID" "EKS_CAPACITY_TYPE" "$EKS_CAPACITY_TYPE" "no" "$EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
}

