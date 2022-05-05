#!/bin/bash

PROJECT_ENCODED=$(rawUrlEncode "${GITLAB_USERNAME}/k8s-digitalocean")

runFormula() {
  #getting real instance type
  DO_CLUSTER_NODE_INSTANCE_TYPE=${DO_CLUSTER_NODE_INSTANCE_TYPE// ([^)]*)/}
  DO_CLUSTER_NODE_INSTANCE_TYPE=${DO_CLUSTER_NODE_INSTANCE_TYPE// /}

  checkGlobalConfig "$DO_CLUSTER_NAME" "do-sample" "digitalocean.cluster.name" "DO_CLUSTER_NAME"
  checkGlobalConfig "$DO_K8S_VERSION" "1.22" "digitalocean.cluster.version" "DO_K8S_VERSION"
  checkGlobalConfig "$DO_CLUSTER_REGION" "nyc1" "digitalocean.cluster.region" "DO_CLUSTER_REGION"
  checkGlobalConfig "$DO_CLUSTER_NODE_INSTANCE_TYPE" "s-2vcpu-2gb" "digitalocean.cluster.nodes.instaceType" "DO_CLUSTER_NODE_INSTANCE_TYPE"
  checkGlobalConfig "$DO_CLUSTER_SIZE" "1" "digitalocean.cluster.nodes.quantitySize" "DO_CLUSTER_SIZE"

  validateDigitalOceanApiToken "$DO_TOKEN"
  validateGitlabUsername "$GITLAB_USERNAME"
  validateGitlabToken "$GITLAB_TOKEN"


  local FORK_RESPONSE_CODE
  FORK_RESPONSE_CODE=$(curl -siX POST -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "https://gitlab.com/api/v4/projects/$(rawUrlEncode "vkpr/k8s-digitalocean")/fork" |\
    head -n 1 | awk -F' ' '{print $2}' 2> /dev/null
  )
  #echo "FORK_RESPONSE_CODE= $FORK_RESPONSE_CODE"
  if [ "$FORK_RESPONSE_CODE" == "409" ];then
    echoColor yellow "Project already forked"
  fi
  
  setVariablesGLAB
  cloneRepository
}

## Set all input into Gitlab environments
setVariablesGLAB() {
  createOrUpdateVariable "$PROJECT_ENCODED" "DO_TOKEN" "$DO_TOKEN" "yes" "$VKPR_ENV_DO_CLUSTER_NAME" "$GITLAB_TOKEN"
}

cloneRepository() {
  git clone -q https://"$GITLAB_USERNAME":"$GITLAB_TOKEN"@gitlab.com/"$GITLAB_USERNAME"/k8s-digitalocean.git "$VKPR_HOME"/tmp/k8s-digitalocean
  cd "$VKPR_HOME"/tmp/k8s-digitalocean || return
  $VKPR_YQ eval -i ".region = \"$VKPR_ENV_DO_CLUSTER_REGION\" |
    .cluster_name = \"$VKPR_ENV_DO_CLUSTER_NAME\" |
    .prefix_version = \"$VKPR_ENV_DO_K8S_VERSION\" |
    .node_pool_default.name = \"${VKPR_ENV_DO_CLUSTER_NAME}-node-pool\" |
    .node_pool_default.size = \"$VKPR_ENV_DO_CLUSTER_NODE_INSTANCE_TYPE\" |
    .node_pool_default.node_count = \"$VKPR_ENV_DO_CLUSTER_SIZE\"
  " "$VKPR_HOME"/tmp/k8s-digitalocean/config/defaults.yml
  git checkout -b "$VKPR_ENV_DO_CLUSTER_NAME"
  git commit -am "[VKPR] Initial configuration defaults.yml"
  git push --set-upstream origin "$VKPR_ENV_DO_CLUSTER_NAME"
  cd - > /dev/null || return
  rm -rf "$VKPR_HOME"/tmp/k8s-digitalocean
}