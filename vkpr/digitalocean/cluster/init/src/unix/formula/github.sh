#!/usr/bin/env bash

runFormulaGithub() {

  formulaInputs
  setCredentials
  validateInputs
  configureCluster
}
formulaInputs() {
  # App values
  checkGlobalConfig "$CLUSTER_NAME" "do-sample" "digitalocean.cluster.name" "DO_CLUSTER_NAME"
  checkGlobalConfig "$K8S_VERSION" "1.27" "digitalocean.cluster.version" "DO_CLUSTER_VERSION"
  checkGlobalConfig "$CLUSTER_REGION" "nyc3" "digitalocean.cluster.region" "DO_CLUSTER_REGION"
  checkGlobalConfig "$CLUSTER_NODE_INSTANCE_TYPE" "s-2vcpu-2gb" "digitalocean.cluster.nodes.instaceType" "DO_CLUSTER_NODES_INSTANCE_TYPE"
  checkGlobalConfig "$CLUSTER_SIZE" "1" "digitalocean.cluster.nodes.quantitySize" "DO_CLUSTER_QUANTITY_SIZE"
}

setCredentials() {
  DO_TOKEN="$($VKPR_JQ -r '.credential.token' $VKPR_CREDENTIAL/digitalocean)"
  GITHUB_USERNAME="$($VKPR_JQ -r '.credential.username' $VKPR_CREDENTIAL/github)"
  GITHUB_TOKEN="$($VKPR_JQ -r '.credential.token' $VKPR_CREDENTIAL/github)"
}

  ### CRIIANDO REPOSITORIO ###
  githubCreateRepo "${CLUSTER_NAME}" "$GITHUB_TOKEN" 

validateInputs() {
  validateDigitalOceanClusterName "$VKPR_ENV_DO_CLUSTER_NAME"
  validateDigitalOceanClusterVersion "$VKPR_ENV_DO_CLUSTER_VERSION"
  validateDigitalOceanClusterRegion "$VKPR_ENV_DO_CLUSTER_REGION"
  validateDigitalOceanInstanceType "$VKPR_ENV_DO_CLUSTER_NODES_INSTANCE_TYPE"
  validateDigitalOceanClusterSize "$VKPR_ENV_DO_CLUSTER_QUANTITY_SIZE"
  validateDigitalOceanApiToken "$DO_TOKEN"
  #validategithubUsername "$GITHUB_USERNAME"
  #validategithubToken "$GITHUB_TOKEN"
 }
  ### CONFIGURANDO SECRECTS ####
  
  
 configureCluster() { 
  VAR_PROJECT_NAME="${GITHUB_USERNAME}/${CLUSTER_NAME}"
  PUBLIC_KEY=$(githubActionsGetPublicKey "$VAR_PROJECT_NAME" "$GITHUB_USERNAME" "$GITHUB_TOKEN")
  echo $PUBLIC_KEY
  githubActionsCreateUpdateSecret "$VAR_PROJECT_NAME" "DO_PAT" "$DO_TOKEN" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
  githubActionsCreateUpdateSecret "$VAR_PROJECT_NAME" "INFRACOST_API_KEY" "$INFRACOST_API_KEY" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
  githubActionsCreateUpdateSecret "$VAR_PROJECT_NAME" "DO_REGION" "$CLUSTER_REGION" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
  githubActionsCreateUpdateSecret "$VAR_PROJECT_NAME" "SPACES_ACCESS_TOKEN" "$SPACES_ACCESS_TOKEN" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
  githubActionsCreateUpdateSecret "$VAR_PROJECT_NAME" "DO_SECRET_KEY" "$SPACES_SECRET_KEY" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
  
  cd "$VKPR_HOME" || exit
  git clone https://github.com/vertigobr/k8s-digitalocean.git
  cd k8s-digitalocean
  ls -ltrh
  rm -rf .git
  git init 
  git remote add origin https://github.com/${GITHUB_USERNAME}/${CLUSTER_NAME}.git 

  $VKPR_YQ eval -i ".cluster_region = \"$VKPR_ENV_DO_CLUSTER_REGION\" |
    .cluster_name = \"$VKPR_ENV_DO_CLUSTER_NAME\" |
    .prefix_version = \"$VKPR_ENV_DO_CLUSTER_VERSION\" |
    .node_pool_default.name = \"${VKPR_ENV_DO_CLUSTER_NAME}-node-pool\" |
    .node_pool_default.size = \"$VKPR_ENV_DO_CLUSTER_NODES_INSTANCE_TYPE\" |
    .node_pool_default.node_count = \"$VKPR_ENV_DO_CLUSTER_QUANTITY_SIZE\"
  " "$VKPR_HOME"/k8s-digitalocean/config/defaults.yml
  ### CONFIGURADO BACKEND S3
  if [ $TERRAFORM_STATE == "space" ]; then
  printf "terraform { \n  backend \"s3\" { \n    endpoint = "https://${DO_REGION}.digitaloceanspaces.com" \n     region = ${DO_REGION} \n    bucket = \"${BUCKET_TERRAFORM}\" \n    key = \" vkpr/${CLUSTER_NAME}.tfstate \" \n    region = \"${DO_REGION}\" \n    skip_credentials_validation = true \n skip_metadata_api_check = true    }\n}" > backend.tf
  cat backend.tf
  fi
  cat "$VKPR_HOME"/k8s-digitalocean/config/defaults.yml
  git add .
  git commit -am "[VKPR] Initial configuration defaults.yml"
  git push --set-upstream origin master 
  cd - > /dev/null || exit
  rm -rf "$VKPR_HOME"/k8s-digitalocean

 }

