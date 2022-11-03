#!/usr/bin/env bash

formulaInputs() {
  # App values
  checkGlobalConfig "$CLUSTER_NAME" "do-sample" "digitalocean.cluster.name" "DO_CLUSTER_NAME"
  checkGlobalConfig "$K8S_VERSION" "1.22" "digitalocean.cluster.version" "DO_CLUSTER_VERSION"
  checkGlobalConfig "$CLUSTER_REGION" "nyc1" "digitalocean.cluster.region" "DO_CLUSTER_REGION"
  checkGlobalConfig "$CLUSTER_NODE_INSTANCE_TYPE" "s-2vcpu-2gb" "digitalocean.cluster.nodes.instaceType" "DO_CLUSTER_NODES_INSTANCE_TYPE"
  checkGlobalConfig "$TERRAFORM_STATE" "gitlab" "digitalocean.cluster.terraformState" "DO_TERRAFORM_STATE"
  checkGlobalConfig "$CLUSTER_SIZE" "1" "digitalocean.cluster.nodes.quantitySize" "DO_CLUSTER_QUANTITY_SIZE"
}

setCredentials() {
  DO_TOKEN="$($VKPR_JQ -r '.credential.token' $VKPR_CREDENTIAL/digitalocean)"

  GITLAB_USERNAME="$($VKPR_JQ -r '.credential.username' $VKPR_CREDENTIAL/gitlab)"
  GITLAB_TOKEN="$($VKPR_JQ -r '.credential.token' $VKPR_CREDENTIAL/gitlab)"

  GITHUB_USERNAME="$($VKPR_JQ -r '.credential.username' $VKPR_CREDENTIAL/github)"
  GITHUB_TOKEN="$($VKPR_JQ -r '.credential.token' $VKPR_CREDENTIAL/github)"

  AWS_REGION="$($VKPR_JQ -r '.credential.region' $VKPR_CREDENTIAL/aws)"

  S3_BUCKET="$($VKPR_JQ -r '.credential.bucket' $VKPR_CREDENTIAL/s3)"
  S3_KEY="$($VKPR_JQ -r '.credential.key' $VKPR_CREDENTIAL/s3)"
}

validateInputs() {
  validateDigitalOceanClusterName "$VKPR_ENV_DO_CLUSTER_NAME"
  validateDigitalOceanClusterVersion "$VKPR_ENV_DO_CLUSTER_VERSION"
  validateDigitalOceanClusterRegion "$VKPR_ENV_DO_CLUSTER_REGION"
  validateDigitalOceanInstanceType "$VKPR_ENV_DO_CLUSTER_NODES_INSTANCE_TYPE"
  validateDigitalOceanClusterSize "$VKPR_ENV_DO_CLUSTER_QUANTITY_SIZE"
  validateDigitalOceanApiToken "$DO_TOKEN"
  validateGitlabUsername "$GITLAB_USERNAME"
}
