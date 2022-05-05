#!/bin/bash

PROJECT_ENCODED=$(rawUrlEncode "${GITLAB_USERNAME}/aws-eks")

runFormula() {
  #getting real instance type
  EKS_CLUSTER_NODE_INSTANCE_TYPE=${EKS_CLUSTER_NODE_INSTANCE_TYPE// ([^)]*)/}
  EKS_CLUSTER_NODE_INSTANCE_TYPE=${EKS_CLUSTER_NODE_INSTANCE_TYPE// /}

  checkGlobalConfig "$EKS_CLUSTER_NAME" "eks-sample" "aws.eks.clusterName" "EKS_CLUSTER_NAME"
  checkGlobalConfig "$EKS_K8S_VERSION" "1.21" "aws.eks.version" "EKS_K8S_VERSION"
  checkGlobalConfig "$EKS_CLUSTER_NODE_INSTANCE_TYPE" "t3.small" "aws.eks.nodes.instaceType" "EKS_CLUSTER_NODE_INSTANCE_TYPE"
  checkGlobalConfig "$EKS_CLUSTER_SIZE" "1" "aws.eks.nodes.quantitySize" "EKS_CLUSTER_SIZE"
  checkGlobalConfig "$EKS_CAPACITY_TYPE" "ON_DEMAND" "aws.eks.nodes.capacityType" "EKS_CAPACITY_TYPE"

  validateAwsSecretKey "$AWS_SECRET_KEY"
  validateAwsAccessKey "$AWS_ACCESS_KEY"
  validateAwsRegion "$AWS_REGION"
  validateGitlabUsername "$GITLAB_USERNAME"
  validateGitlabToken "$GITLAB_TOKEN"
  [[ "$TERRAFORM_STATE" == "Terraform Cloud" ]] && validateTFCloudToken "$TERRAFORMCLOUD_API_TOKEN"

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
  cloneRepository
}

## Set all input into Gitlab environments
setVariablesGLAB() {
  [[ "$TERRAFORM_STATE" == "Terraform Cloud" ]] && createOrUpdateVariable "$PROJECT_ENCODED" "TF_CLOUD_TOKEN" "$TF_CLOUD_TOKEN" "yes" "$EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
  createOrUpdateVariable "$PROJECT_ENCODED" "AWS_ACCESS_KEY" "$AWS_ACCESS_KEY" "yes" "$EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
  createOrUpdateVariable "$PROJECT_ENCODED" "AWS_SECRET_KEY" "$AWS_SECRET_KEY" "yes" "$EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
  createOrUpdateVariable "$PROJECT_ENCODED" "AWS_REGION" "$AWS_REGION" "no" "$EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
}

cloneRepository() {
  git clone -q https://"$GITLAB_USERNAME":"$GITLAB_TOKEN"@gitlab.com/"$GITLAB_USERNAME"/aws-eks.git "$VKPR_HOME"/tmp/aws-eks
  cd "$VKPR_HOME"/tmp/aws-eks || exit
  $VKPR_YQ eval -i "del(.node_groups) |
    .cluster_name = \"$VKPR_ENV_EKS_CLUSTER_NAME\" |
    .cluster_version = \"$VKPR_ENV_EKS_K8S_VERSION\" |
    .node_groups.${VKPR_ENV_EKS_CLUSTER_NAME}.desired_capacity = \"$EKS_CLUSTER_SIZE\" |
    .node_groups.${VKPR_ENV_EKS_CLUSTER_NAME}.max_capacity = \"$(( EKS_CLUSTER_SIZE + 2 ))\" |
    .node_groups.${VKPR_ENV_EKS_CLUSTER_NAME}.min_capacity = \"$EKS_CLUSTER_SIZE\" |
    .node_groups.${VKPR_ENV_EKS_CLUSTER_NAME}.ami_type = \"AL2_x86_64\" |
    .node_groups.${VKPR_ENV_EKS_CLUSTER_NAME}.instance_types[0] = \"$VKPR_ENV_EKS_CLUSTER_NODE_INSTANCE_TYPE\" |
    .node_groups.${VKPR_ENV_EKS_CLUSTER_NAME}.capacity_type = \"$VKPR_ENV_EKS_CAPACITY_TYPE\"
  " "$VKPR_HOME"/tmp/aws-eks/config/defaults.yml
  git checkout -b "$VKPR_ENV_EKS_CLUSTER_NAME"
  git commit -am "[VKPR] Initial configuration defaults.yml"
  git push --set-upstream origin "$VKPR_ENV_EKS_CLUSTER_NAME"
  cd - > /dev/null || exit
  rm -rf "$VKPR_HOME"/tmp/aws-eks
}