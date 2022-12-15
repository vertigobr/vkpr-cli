#!/usr/bin/env bash
setproviderrun() {
  local PROJECT_ENCODED FORK_RESPONSE_CODE;

  # installAWS


 PROJECT_ENCODED=$(rawUrlEncode "${GITLAB_USERNAME}/aws-eks")
  if [ $PROJECT_LOCATION == "groups" ]; then
    FORK_RESPONSE_CODE=$(curl -siX POST -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
      -d "namespace_path=$PROJECT_LOCATION_PATH" \
      "https://gitlab.com/api/v4/projects/$(rawUrlEncode "vkpr/aws-eks")/fork" |\
      head -n1 | awk -F' ' '{print $2}'
    )
    GROUP_ID=$(curl -s -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "https://gitlab.com/api/v4/groups" |\
      $VKPR_JQ -r ".[] | select(.web_url | contains(\"$PROJECT_LOCATION_PATH\")) | .id"
    )
    debug "GROUP_ID=$GROUP_ID"
    PROJECT_ID=$(curl -s -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "https://gitlab.com/api/v4/groups/$GROUP_ID/projects" |\
      $VKPR_JQ -r ".[] | select(.path_with_namespace | contains(\"$PROJECT_LOCATION_PATH/aws-eks\")) | .id"
    )
    debug "PROJECT_ID=$PROJECT_ID"
  else
    FORK_RESPONSE_CODE=$(curl -siX POST -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
      "https://gitlab.com/api/v4/projects/$(rawUrlEncode "vkpr/aws-eks")/fork" |\
      head -n1 | awk -F' ' '{print $2}'
    )
  fi

  debug "FORK_RESPONSE_CODE=$FORK_RESPONSE_CODE"
  if [ "$FORK_RESPONSE_CODE" == "409" ];then
    boldNotice "Project already forked"
  fi

  echo "${VKPR_ENV_EKS_CLUSTER_NAME}"

formulaInputs() {
  # App values
  checkGlobalConfig "$CLUSTER_NAME" "eks-sample" "aws.eks.clusterName" "EKS_CLUSTER_NAME"
  checkGlobalConfig "$K8S_VERSION" "1.23" "aws.eks.version" "EKS_VERSION"
  checkGlobalConfig "$CLUSTER_NODE_INSTANCE_TYPE.$CLUSTER_NODE_INSTANCE_SIZE" "t3.small" "aws.eks.nodes.instanceType" "EKS_NODES_INSTANCE_TYPE"
  checkGlobalConfig "$CLUSTER_SIZE" "1" "aws.eks.nodes.quantitySize" "EKS_NODES_QUANTITY_SIZE"
  checkGlobalConfig "$CAPACITY_TYPE" "on_demand" "aws.eks.nodes.capacityType" "EKS_NODES_CAPACITY_TYPE"
  checkGlobalConfig "$TERRAFORM_STATE" "gitlab" "aws.eks.terraformState" "EKS_TERRAFORM_STATE"
}

setCredentials() {
  AWS_ACCESS_KEY="$($VKPR_JQ -r '.credential.accesskeyid' $VKPR_CREDENTIAL/aws)"
  AWS_SECRET_KEY="$($VKPR_JQ -r '.credential.secretaccesskey' $VKPR_CREDENTIAL/aws)"
  AWS_REGION="$($VKPR_JQ -r '.credential.region' $VKPR_CREDENTIAL/aws)"
  GITLAB_USERNAME="$($VKPR_JQ -r '.credential.username' $VKPR_CREDENTIAL/gitlab)"
  GITLAB_TOKEN="$($VKPR_JQ -r '.credential.token' $VKPR_CREDENTIAL/gitlab)"
}

validateInputs() {
  validateAwsSecretKey "$AWS_SECRET_KEY"
  validateAwsAccessKey "$AWS_ACCESS_KEY"
  validateAwsRegion "$AWS_REGION"
  validateGitlabUsername "$GITLAB_USERNAME"
  validateGitlabToken "$GITLAB_TOKEN"
  [[ "$VKPR_ENV_EKS_TERRAFORM_STATE" == "terraform-cloud" ]] && validateTFCloudToken "$TERRAFORMCLOUD_API_TOKEN"

  validateEksClusterName "$VKPR_ENV_EKS_CLUSTER_NAME"
  validateEksVersion "$VKPR_ENV_EKS_VERSION"
  validateEksNodeInstanceType "$VKPR_ENV_EKS_NODES_INSTANCE_TYPE"

  validateEksClusterSize "$VKPR_ENV_EKS_NODES_QUANTITY_SIZE"
  validateEksCapacityType "$VKPR_ENV_EKS_NODES_CAPACITY_TYPE"
  validateEksStoreTfState "$VKPR_ENV_EKS_TERRAFORM_STATE"
}

setVariablesGLAB() {
  [[ $PROJECT_LOCATION == "groups" ]] && PROJECT_IDENTIFIER=$PROJECT_ID || PROJECT_IDENTIFIER=$PROJECT_ENCODED
  [[ "$VKPR_ENV_EKS_TERRAFORM_STATE" == "terraform-cloud" ]] && createOrUpdateVariable "$PROJECT_IDENTIFIER" "TF_CLOUD_TOKEN" "$TF_CLOUD_TOKEN" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
  createOrUpdateVariable "$PROJECT_IDENTIFIER" "AWS_ACCESS_KEY" "$AWS_ACCESS_KEY" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
  createOrUpdateVariable "$PROJECT_IDENTIFIER" "AWS_SECRET_KEY" "$AWS_SECRET_KEY" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
  createOrUpdateVariable "$PROJECT_IDENTIFIER" "AWS_REGION" "$AWS_REGION" "no" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
  createOrUpdateVariable "$PROJECT_IDENTIFIER" "CI_GITLAB_TOKEN" "$GITLAB_TOKEN" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
}

cloneRepository() {
  [[ $PROJECT_LOCATION == "groups" ]] && PROJECT_PATH="$PROJECT_LOCATION_PATH" || PROJECT_PATH="$GITLAB_USERNAME"
  git clone -q https://"$GITLAB_USERNAME":"$GITLAB_TOKEN"@gitlab.com/"$PROJECT_PATH"/aws-eks.git "$VKPR_HOME"/tmp/aws-eks
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
  ### CONFIGURADO BACKEND S3
  if [ $TERRAFORM_STATE == "s3" ]; then
  printf "terraform { \n  backend \"s3\" { \n    bucket = \"${BUCKET_TERRAFORM}\" \n    key    = \"${BUCKET_TERRAFORM}.tfstate\" \n    region = \"${AWS_REGION}\" \n  }\n}" > backend.tf
  cat backend.tf
  fi
  mergeVkprValuesExtraArgs "aws.eks" "$VKPR_HOME"/tmp/aws-eks/config/defaults.yml
  git checkout -b "$VKPR_ENV_EKS_CLUSTER_NAME"
  git commit -am "[VKPR] Initial configuration defaults.yml"
  git push --set-upstream origin "$VKPR_ENV_EKS_CLUSTER_NAME"
  cd - > /dev/null || exit
  rm -rf "$VKPR_HOME"/tmp/aws-eks
 }
}
