#!/usr/bin/env bash

createRepo() {
  GROUP_NAME=$(echo $PROJECT_LOCATION_PATH | sed 's,/[^/]*$,,')
  if [ $PROJECT_LOCATION == "groups" ]; then
    GROUP_ID=$(curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://$GITLAB_URL/api/v4/groups" |\
      $VKPR_JQ -r ".[] | select(.web_url | contains(\"$GROUP_NAME\")) | select(.full_path==\"$GROUP_NAME\") | .id"
    )
    debug "GROUP_ID=$GROUP_ID"

    SUBGROUP_ID=$(curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" https://$GITLAB_URL/api/v4/groups/$GROUP_ID/subgroups |\
      $VKPR_JQ -r ".[] | select(.web_url | contains(\"$PROJECT_LOCATION_PATH\")) | .id"
    )
    debug "SUBGROUP_ID=$SUBGROUP_ID"

    CREATE_REPO=$(curl -sX POST -w "%{http_code}" -o /dev/null \
      -H "Content-Type: application/json" -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
      -d "{\"name\": \"vkpr_digitalocean_cluster\",\"namespace_id\": \"$SUBGROUP_ID\",\"path\": \"vkpr_digitalocean_cluster\",\"initialize_with_readme\": \"false\"}" \
      https://$GITLAB_URL/api/v4/projects
    )
    debug "CREATE_REPO=$CREATE_REPO"
  else
    CREATE_REPO=$(curl -sX POST -w "%{http_code}" -o /dev/null \
      -H "Content-Type: application/json" -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
      -d "{\"name\": \"vkpr_digitalocean_cluster\",\"path\": \"vkpr_digitalocean_cluster\",\"initialize_with_readme\": \"false\"}" \
      https://$GITLAB_URL/api/v4/projects
    )
    debug "CREATE_REPO=$CREATE_REPO"
  fi

  case $CREATE_REPO in
    201)
      info "Repository ${PROJECT_LOCATION_PATH:-$GITLAB_USERNAME}/vkpr_digitalocean_cluster created"
    ;;
    400)
      error "Project already exists"
    ;;
    *)
      boldError "Unexpected error"
      exit
    ;;
  esac

  REPO_ID=$(curl -sX GET -H "Content-Type: application/json" -H "PRIVATE-TOKEN: $GITLAB_TOKEN" https://$GITLAB_URL/api/v4/projects |\
    $VKPR_JQ -r ".[] | select(.name==\"vkpr_digitalocean_cluster\").id"
  )

  if [[ $PROJECT_LOCATION == "groups" ]]; then
    PROJECT_IDENTIFIER=$REPO_ID
    PROJECT_DESTINATION=$PROJECT_LOCATION_PATH
  else
    PROJECT_IDENTIFIER=$(rawUrlEncode "${GITLAB_USERNAME}/vkpr_digitalocean_cluster")
    PROJECT_DESTINATION=$GITLAB_USERNAME
  fi

  debug "PROJECT_IDENTIFIER=$PROJECT_IDENTIFIER"
}

cloneRepository() {
  git clone -q https://gitlab.com/vkpr/k8s-digitalocean.git "$VKPR_HOME"/tmp/k8s-digitalocean
  cd "$VKPR_HOME"/tmp/k8s-digitalocean || exit
  git remote remove origin
  git remote add origin https://$GITLAB_USERNAME:$GITLAB_TOKEN@$GITLAB_URL/$PROJECT_DESTINATION/vkpr_digitalocean_cluster.git
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
    gitlab)
      $VKPR_YQ -i ".include[0].remote = \"https://gitlab.com/vkpr/templates/-/raw/main/Full-Workflow-GitLab-Backend.gitlab-ci.yml\" |
        .variables.CI_GITLAB_TOKEN = \"\$CI_GITLAB_TOKEN\"" "$VKPR_HOME"/tmp/k8s-digitalocean/.gitlab-ci.yml
    ;;
    s3)
      sed -i "s/http/s3/g" "$VKPR_HOME"/tmp/k8s-digitalocean/backend.tf
      $VKPR_YQ -i ".include[0].remote = \"https://gitlab.com/vkpr/templates/-/raw/main/Full-Workflow-S3-Backend.gitlab-ci.yml\" |
        .variables.S3_BUCKET = \"\$S3_BUCKET\" |
        .variables.S3_KEY = \"\$S3_KEY\" |
        .variables.AWS_REGION = \"\$AWS_REGION\"" "$VKPR_HOME"/tmp/k8s-digitalocean/.gitlab-ci.yml
    ;;
    terraform_cloud)
      sed -i "s/http/remote/g" "$VKPR_HOME"/tmp/k8s-digitalocean/backend.tf
      $VKPR_YQ -i ".include[0].remote = \"https://gitlab.com/vkpr/templates/-/raw/main/Full-Workflow-TerraformCloud-Backend.gitlab-ci.yml\"" "$VKPR_HOME"/tmp/k8s-digitalocean/.gitlab-ci.yml
    ;;
  esac
}

setVariablesRepo() {
  createOrUpdateVariable "$PROJECT_IDENTIFIER" "DO_TOKEN" "$DO_TOKEN" "yes" "$VKPR_ENV_DO_CLUSTER_NAME" "$GITLAB_TOKEN"

  case $VKPR_ENV_DO_TERRAFORM_STATE in
    gitlab)
      createOrUpdateVariable "$PROJECT_IDENTIFIER" "CI_GITLAB_TOKEN" "$GITLAB_TOKEN" "yes" "$VKPR_ENV_DO_CLUSTER_NAME" "$GITLAB_TOKEN"
    ;;
    s3)
      createOrUpdateVariable "$PROJECT_IDENTIFIER" "S3_BUCKET" "$S3_BUCKET" "yes" "$VKPR_ENV_DO_CLUSTER_NAME" "$GITLAB_TOKEN"
      createOrUpdateVariable "$PROJECT_IDENTIFIER" "S3_KEY" "$S3_KEY" "yes" "$VKPR_ENV_DO_CLUSTER_NAME" "$GITLAB_TOKEN"
      createOrUpdateVariable "$PROJECT_IDENTIFIER" "AWS_REGION" "$AWS_REGION" "no" "$VKPR_ENV_DO_CLUSTER_NAME" "$GITLAB_TOKEN"
    ;;
    terraform_cloud)
      createOrUpdateVariable "$PROJECT_IDENTIFIER" "TF_CLOUD_TOKEN" "$TF_CLOUD_TOKEN" "yes" "$VKPR_ENV_DO_CLUSTER_NAME" "$GITLAB_TOKEN"
    ;;
  esac
}


createRepo
cloneRepository
setVariablesRepo
