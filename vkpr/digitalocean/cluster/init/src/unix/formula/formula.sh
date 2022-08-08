#!/usr/bin/env bash

runFormula() {
  local DO_CLUSTER_NODE_INSTANCE_TYPE PROJECT_ENCODED FORK_RESPONSE_CODE;

  #getting real instance type
  DO_CLUSTER_NODE_INSTANCE_TYPE=${DO_CLUSTER_NODE_INSTANCE_TYPE// ([^)]*)/}
  DO_CLUSTER_NODE_INSTANCE_TYPE=${DO_CLUSTER_NODE_INSTANCE_TYPE// /}

  formulaInputs
  setCredentials
  validateInputs

  PROJECT_ENCODED=$(rawUrlEncode "${GITLAB_USERNAME}/aws-eks")
  FORK_RESPONSE_CODE=$(curl -siX POST -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "https://gitlab.com/api/v4/projects/$(rawUrlEncode "vkpr/aws-eks")/fork" |\
    head -n 1 | awk -F' ' '{print $2}'
  )

  debug "FORK_RESPONSE_CODE=$FORK_RESPONSE_CODE"
  if [ "$FORK_RESPONSE_CODE" == "409" ];then
    boldNotice "Project already forked"
  fi

  setVariablesGLAB
  cloneRepository
}

formulaInputs() {
  # App values
  checkGlobalConfig "$DO_CLUSTER_NAME" "do-sample" "digitalocean.cluster.name" "DO_CLUSTER_NAME"
  checkGlobalConfig "$DO_K8S_VERSION" "1.22" "digitalocean.cluster.version" "DO_CLUSTER_VERSION"
  checkGlobalConfig "$DO_CLUSTER_REGION" "nyc1" "digitalocean.cluster.region" "DO_CLUSTER_REGION"
  checkGlobalConfig "$DO_CLUSTER_NODE_INSTANCE_TYPE" "s-2vcpu-2gb" "digitalocean.cluster.nodes.instaceType" "DO_CLUSTER_NODES_INSTANCE_TYPE"
  checkGlobalConfig "$DO_CLUSTER_SIZE" "1" "digitalocean.cluster.nodes.quantitySize" "DO_CLUSTER_QUANTITY_SIZE"
}

setCredentials() {
  DO_TOKEN="$($VKPR_JQ -r '.credential.token' $VKPR_CREDENTIAL/digitalocean)"
  GITLAB_USERNAME="$($VKPR_JQ -r '.credential.username' $VKPR_CREDENTIAL/gitlab)"
  GITLAB_TOKEN="$($VKPR_JQ -r '.credential.token' $VKPR_CREDENTIAL/gitlab)"
}

validateInputs() {
  validateDigitalOceanClusterName "$DO_CLUSTER_NAME"
  validateDigitalOceanClusterVersion "$DO_CLUSTER_VERSION"
  validateDigitalOceanClusterRegion "$DO_CLUSTER_REGION"
  validateDigitalOceanInstanceType "$DO_CLUSTER_NODE_INSTANCE_TYPE"
  validateDigitalOceanClusterSize "$DO_CLUSTER_SIZE"
  validateDigitalOceanApiToken "$DO_TOKEN"
  validateGitlabUsername "$GITLAB_USERNAME"
  validateGitlabToken "$GITLAB_TOKEN"
}

setVariablesGLAB() {
  createOrUpdateVariable "$PROJECT_ENCODED" "DO_TOKEN" "$DO_TOKEN" "yes" "$VKPR_ENV_DO_CLUSTER_NAME" "$GITLAB_TOKEN"
}

cloneRepository() {
  git clone -q https://"$GITLAB_USERNAME":"$GITLAB_TOKEN"@gitlab.com/"$GITLAB_USERNAME"/k8s-digitalocean.git "$VKPR_HOME"/tmp/k8s-digitalocean
  cd "$VKPR_HOME"/tmp/k8s-digitalocean || return
  $VKPR_YQ eval -i ".region = \"$VKPR_ENV_DO_CLUSTER_REGION\" |
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
