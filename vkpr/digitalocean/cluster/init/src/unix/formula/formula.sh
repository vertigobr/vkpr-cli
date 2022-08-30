#!/usr/bin/env bash

runFormula() {
  local PROJECT_ENCODED FORK_RESPONSE_CODE;

  formulaInputs
  setCredentials
  validateInputs

  PROJECT_ENCODED=$(rawUrlEncode "${GITLAB_USERNAME}/k8s-digitalocean")
  if [ $PROJECT_LOCATION == "groups" ]; then
    FORK_RESPONSE_CODE=$(curl -siX POST -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
      -d "namespace_path=$PROJECT_LOCATION_PATH" \
      "https://gitlab.com/api/v4/projects/$(rawUrlEncode "vkpr/k8s-digitalocean")/fork" |\
      head -n1 | awk -F' ' '{print $2}'
    )
    GROUP_ID=$(curl -s -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "https://gitlab.com/api/v4/groups" |\
      $VKPR_JQ -r ".[] | select(.web_url | contains(\"$PROJECT_LOCATION_PATH\")) | .id"
    )
    debug "GROUP_ID=$GROUP_ID"
    PROJECT_ID=$(curl -s -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "https://gitlab.com/api/v4/groups/$GROUP_ID/projects" |\
      $VKPR_JQ -r ".[] | select(.path_with_namespace | contains(\"$PROJECT_LOCATION_PATH/k8s-digitalocean\")) | .id"
    )
    debug "PROJECT_ID=$PROJECT_ID"
  else
    FORK_RESPONSE_CODE=$(curl -siX POST -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
      "https://gitlab.com/api/v4/projects/$(rawUrlEncode "vkpr/k8s-digitalocean")/fork" |\
      head -n1 | awk -F' ' '{print $2}'
    )
  fi


  debug "FORK_RESPONSE_CODE=$FORK_RESPONSE_CODE"
  if [ "$FORK_RESPONSE_CODE" == "409" ];then
    boldNotice "Project already forked"
  fi

  setVariablesGLAB
  cloneRepository
}

formulaInputs() {
  # App values
  checkGlobalConfig "$CLUSTER_NAME" "do-sample" "digitalocean.cluster.name" "DO_CLUSTER_NAME"
  checkGlobalConfig "$K8S_VERSION" "1.22" "digitalocean.cluster.version" "DO_CLUSTER_VERSION"
  checkGlobalConfig "$CLUSTER_REGION" "nyc1" "digitalocean.cluster.region" "DO_CLUSTER_REGION"
  checkGlobalConfig "$CLUSTER_NODE_INSTANCE_TYPE" "s-2vcpu-2gb" "digitalocean.cluster.nodes.instaceType" "DO_CLUSTER_NODES_INSTANCE_TYPE"
  checkGlobalConfig "$CLUSTER_SIZE" "1" "digitalocean.cluster.nodes.quantitySize" "DO_CLUSTER_QUANTITY_SIZE"
}

setCredentials() {
  DO_TOKEN="$($VKPR_JQ -r '.credential.token' $VKPR_CREDENTIAL/digitalocean)"
  GITLAB_USERNAME="$($VKPR_JQ -r '.credential.username' $VKPR_CREDENTIAL/gitlab)"
  GITLAB_TOKEN="$($VKPR_JQ -r '.credential.token' $VKPR_CREDENTIAL/gitlab)"
}

validateInputs() {
  validateDigitalOceanClusterName "$VKPR_ENV_DO_CLUSTER_NAME"
  validateDigitalOceanClusterVersion "$VKPR_ENV_DO_CLUSTER_VERSION"
  validateDigitalOceanClusterRegion "$VKPR_ENV_DO_CLUSTER_REGION"
  validateDigitalOceanInstanceType "$VKPR_ENV_DO_CLUSTER_NODES_INSTANCE_TYPE"
  validateDigitalOceanClusterSize "$VKPR_ENV_DO_CLUSTER_QUANTITY_SIZE"
  validateDigitalOceanApiToken "$DO_TOKEN"
  validateGitlabUsername "$GITLAB_USERNAME"
  validateGitlabToken "$GITLAB_TOKEN"
}

setVariablesGLAB() {
  [[ $PROJECT_LOCATION == "groups" ]] && PROJECT_IDENTIFIER=$PROJECT_ID || PROJECT_IDENTIFIER=$PROJECT_ENCODED
  createOrUpdateVariable "$PROJECT_IDENTIFIER" "DO_TOKEN" "$DO_TOKEN" "yes" "$VKPR_ENV_DO_CLUSTER_NAME" "$GITLAB_TOKEN"
  createOrUpdateVariable "$PROJECT_IDENTIFIER" "CI_GITLAB_TOKEN" "$GITLAB_TOKEN" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
}

cloneRepository() {
  [[ $PROJECT_LOCATION == "groups" ]] && PROJECT_PATH="$PROJECT_LOCATION_PATH" || PROJECT_PATH="$GITLAB_USERNAME"
  git clone -q https://"$GITLAB_USERNAME":"$GITLAB_TOKEN"@gitlab.com/"$PROJECT_PATH"/k8s-digitalocean.git "$VKPR_HOME"/tmp/k8s-digitalocean
  cd "$VKPR_HOME"/tmp/k8s-digitalocean || exit
  $VKPR_YQ eval -i ".cluster_region = \"$VKPR_ENV_DO_CLUSTER_REGION\" |
    .cluster_name = \"$VKPR_ENV_DO_CLUSTER_NAME\" |
    .prefix_version = \"$VKPR_ENV_DO_CLUSTER_VERSION\" |
    .node_pool_default.name = \"${VKPR_ENV_DO_CLUSTER_NAME}-node-pool\" |
    .node_pool_default.size = \"$VKPR_ENV_DO_CLUSTER_NODES_INSTANCE_TYPE\" |
    .node_pool_default.node_count = \"$VKPR_ENV_DO_CLUSTER_QUANTITY_SIZE\"
  " "$VKPR_HOME"/tmp/k8s-digitalocean/config/defaults.yml
  mergeVkprValuesExtraArgs "digitalocean.cluster" "$VKPR_HOME"/tmp/k8s-digitalocean/config/defaults.yml
  git checkout -b "$VKPR_ENV_DO_CLUSTER_NAME"
  git commit -am "[VKPR] Initial configuration defaults.yml"
  git push --set-upstream origin "$VKPR_ENV_DO_CLUSTER_NAME"
  cd - > /dev/null || return
  rm -rf "$VKPR_HOME"/tmp/k8s-digitalocean
}
