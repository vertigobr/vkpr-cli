#!/bin/bash

runFormula() {
  local RIT_CREDENTIALS_PATH=~/.rit/credentials/default
  AWS_ACCESS_KEY="$($VKPR_JQ -r '.credential.accesskeyid' $RIT_CREDENTIALS_PATH/aws)"
  AWS_SECRET_KEY="$($VKPR_JQ -r '.credential.secretaccesskey' $RIT_CREDENTIALS_PATH/aws)"
  AWS_REGION="$($VKPR_JQ -r '.credential.region' $RIT_CREDENTIALS_PATH/aws)"
  GITLAB_USERNAME="$($VKPR_JQ -r '.credential.username' $RIT_CREDENTIALS_PATH/gitlab)"
  GITLAB_TOKEN="$($VKPR_JQ -r '.credential.token' $RIT_CREDENTIALS_PATH/gitlab)"
  #getting real instance type
  EKS_CLUSTER_NODE_INSTANCE_TYPE=${EKS_CLUSTER_NODE_INSTANCE_TYPE// ([^)]*)/}
  EKS_CLUSTER_NODE_INSTANCE_TYPE=${EKS_CLUSTER_NODE_INSTANCE_TYPE// /}

  checkGlobalConfig "$EKS_CLUSTER_NAME" "eks-sample" "aws.eks.clusterName" "EKS_CLUSTER_NAME"
  checkGlobalConfig "$EKS_K8S_VERSION" "1.20" "aws.eks.version" "EKS_VERSION"
  checkGlobalConfig "$EKS_CLUSTER_NODE_INSTANCE_TYPE" "t3.small" "aws.eks.nodes.instaceType" "EKS_NODES_INSTANCE_TYPE"
  checkGlobalConfig "$EKS_CLUSTER_SIZE" "1" "aws.eks.nodes.quantitySize" "EKS_NODES_QUANTITY_SIZE"
  checkGlobalConfig "$EKS_CAPACITY_TYPE" "on_demand" "aws.eks.nodes.capacityType" "EKS_NODES_CAPACITY_TYPE"
  checkGlobalConfig "$TERRAFORM_STATE" "gitlab" "aws.eks.terraformState" "EKS_TERRAFORM_STATE"

  validateAwsSecretKey "$AWS_SECRET_KEY"
  validateAwsAccessKey "$AWS_ACCESS_KEY"
  validateAwsRegion "$AWS_REGION"
  validateGitlabUsername "$GITLAB_USERNAME"
  validateGitlabToken "$GITLAB_TOKEN"

  validateEksClusterName "$VKPR_ENV_EKS_CLUSTER_NAME"
  validateEksVersion "$VKPR_ENV_EKS_VERSION"
  validateEksNodeInstanceType "$VKPR_ENV_EKS_NODES_INSTANCE_TYPE"
  validateEksClusterSize "$VKPR_ENV_EKS_NODES_QUANTITY_SIZE"
  validateEksCapacityType "$VKPR_ENV_EKS_NODES_CAPACITY_TYPE"
  validateEksStoreTfState "$VKPR_ENV_EKS_TERRAFORM_STATE"

  [[ "$VKPR_ENV_EKS_TERRAFORM_STATE" == "terraform-cloud" ]] && validateTFCloudToken "$TERRAFORMCLOUD_API_TOKEN"

  local PROJECT_ENCODED=$(rawUrlEncode "${GITLAB_USERNAME}/aws-eks")
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
  [[ "$VKPR_ENV_EKS_TERRAFORM_STATE" == "terraform-cloud" ]] && createOrUpdateVariable "$PROJECT_ENCODED" "TF_CLOUD_TOKEN" "$TF_CLOUD_TOKEN" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
  createOrUpdateVariable "$PROJECT_ENCODED" "AWS_ACCESS_KEY" "$AWS_ACCESS_KEY" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
  createOrUpdateVariable "$PROJECT_ENCODED" "AWS_SECRET_KEY" "$AWS_SECRET_KEY" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
  createOrUpdateVariable "$PROJECT_ENCODED" "AWS_REGION" "$AWS_REGION" "no" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
}

cloneRepository() {
  git clone -q https://"$GITLAB_USERNAME":"$GITLAB_TOKEN"@gitlab.com/"$GITLAB_USERNAME"/aws-eks.git "$VKPR_HOME"/tmp/aws-eks
  cd "$VKPR_HOME"/tmp/aws-eks || exit
  $VKPR_YQ eval -i "del(.node_groups) |
    .cluster_name = \"$VKPR_ENV_EKS_CLUSTER_NAME\" |
    .cluster_version = \"$VKPR_ENV_EKS_VERSION\" |
    .node_groups.${VKPR_ENV_EKS_CLUSTER_NAME}.desired_capacity = \"$VKPR_ENV_EKS_NODES_QUANTITY_SIZE\" |
    .node_groups.${VKPR_ENV_EKS_CLUSTER_NAME}.max_capacity = \"$(( VKPR_ENV_EKS_NODES_QUANTITY_SIZE + 2 ))\" |
    .node_groups.${VKPR_ENV_EKS_CLUSTER_NAME}.min_capacity = \"$VKPR_ENV_EKS_NODES_QUANTITY_SIZE\" |
    .node_groups.${VKPR_ENV_EKS_CLUSTER_NAME}.ami_type = \"AL2_x86_64\" |
    .node_groups.${VKPR_ENV_EKS_CLUSTER_NAME}.instance_types[0] = \"$VKPR_ENV_EKS_NODES_INSTANCE_TYPE\" |
    .node_groups.${VKPR_ENV_EKS_CLUSTER_NAME}.capacity_type = \"${VKPR_ENV_EKS_NODES_CAPACITY_TYPE^^}\"
  " "$VKPR_HOME"/tmp/aws-eks/config/defaults.yml
  mergeVkprValuesExtraArgs "aws.eks" "$VKPR_HOME"/tmp/aws-eks/config/defaults.yml
  git checkout -b "$VKPR_ENV_EKS_CLUSTER_NAME"
  git commit -am "[VKPR] Initial configuration defaults.yml"
  git push --set-upstream origin "$VKPR_ENV_EKS_CLUSTER_NAME"
  cd - > /dev/null || exit
  rm -rf "$VKPR_HOME"/tmp/aws-eks
}