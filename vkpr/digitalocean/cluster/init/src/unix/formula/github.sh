#!/usr/bin/env bash

createRepo() {
  if [ $PROJECT_LOCATION == "groups" ]; then
    CREATE_REPO=$(curl -sX POST -w "%{http_code}" -o /dev/null \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -d "{\"name\": \"vkpr_digitalocean_cluster\",\"homepage\":\"https://github.com\",\"visibility\": \"private\"}" \
      https://api.github.com/orgs/$PROJECT_LOCATION_PATH/repos
    )
    debug "CREATE_REPO=$CREATE_REPO"
  else
    CREATE_REPO=$(curl -sX POST -w "%{http_code}" -o /dev/null \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -d "{\"name\": \"vkpr_digitalocean_cluster\",\"homepage\":\"https://github.com\",\"visibility\": \"private\"}" \
      https://api.github.com/user/repos
    )
    debug "CREATE_REPO=$CREATE_REPO"
  fi

  case $CREATE_REPO in
    201)
      info "Repository $PROJECT_NAME created"
    ;;
    403)
      error "Project already exists"
    ;;
    *)
      boldError "Unexpected error"
      exit
    ;;
  esac
}

cloneRepository() {
  git clone -q https://gitlab.com/vkpr/k8s-digitalocean.git "$VKPR_HOME"/tmp/k8s-digitalocean
  cd "$VKPR_HOME"/tmp/k8s-digitalocean || exit
  git remote remove origin
  git remote add origin https://$GITHUB_USERNAME:$GITHUB_TOKEN@github.com/${PROJECT_NAME}.git
  git checkout -b "$VKPR_ENV_DO_CLUSTER_NAME"
  configureConfigFile
  configureBackend
  git commit -q -am "[VKPR] Initial configuration defaults.yml"
  git push -q --all
  cd - > /dev/null || exit
  rm -fr "$VKPR_HOME"/tmp/k8s-digitalocean
}

configureConfigFile() {
  $VKPR_YQ eval -i ".cluster_region = \"$VKPR_ENV_DO_CLUSTER_REGION\" |
    .cluster_name = \"$VKPR_ENV_DO_CLUSTER_NAME\" |
    .prefix_version = \"$VKPR_ENV_DO_CLUSTER_VERSION\" |
    .node_pool_default.name = \"${VKPR_ENV_DO_CLUSTER_NAME}-node-pool\" |
    .node_pool_default.size = \"$VKPR_ENV_DO_CLUSTER_NODES_INSTANCE_TYPE\" |
    .node_pool_default.node_count = \"$VKPR_ENV_DO_CLUSTER_QUANTITY_SIZE\"
  " "$VKPR_HOME"/tmp/k8s-digitalocean/config/defaults.yml
  mergeVkprValuesExtraArgs "digitalocean.cluster" "$VKPR_HOME"/tmp/k8s-digitalocean/config/defaults.yml
}

configureBackend() {
  case $VKPR_ENV_DO_TERRAFORM_STATE in
    s3)
      sed -i "s/http/s3/g" "$VKPR_HOME"/tmp/k8s-digitalocean/backend.tf
    ;;
    terraform_cloud)
      sed -i "s/http/remote/g" "$VKPR_HOME"/tmp/k8s-digitalocean/backend.tf
    ;;
  esac
}

setVariablesRepo() {
  PUBLIC_KEY=$(githubActionsGetPublicKey "$PROJECT_NAME" "$GITHUB_USERNAME" "$GITHUB_TOKEN")
  debug "PUBLIC_KEY=$PUBLIC_KEY"

  githubActionsCreateUpdateSecret "$PROJECT_NAME" "DO_TOKEN" "$DO_TOKEN" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"

  case $VKPR_ENV_DO_TERRAFORM_STATE in
    s3)
      githubActionsCreateUpdateSecret "$PROJECT_NAME" "S3_BUCKET" "$S3_BUCKET" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
      githubActionsCreateUpdateSecret "$PROJECT_NAME" "S3_KEY" "$S3_KEY" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
      githubActionsCreateUpdateSecret "$PROJECT_NAME" "AWS_REGION" "$AWS_REGION" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
    ;;
    terraform_cloud)
      githubActionsCreateUpdateSecret "$PROJECT_NAME" "TF_CLOUD_TOKEN" "$TF_CLOUD_TOKEN" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
    ;;
  esac
}

[ $PROJECT_LOCATION == "groups" ] && PROJECT_NAME="$PROJECT_LOCATION_PATH/vkpr_digitalocean_cluster" || PROJECT_NAME="$GITHUB_USERNAME/vkpr_digitalocean_cluster"
debug "PROJECT_NAME=$PROJECT_NAME"

createRepo
cloneRepository
setVariablesRepo
