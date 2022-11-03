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
      -d "{\"name\": \"vkpr_aws_eks\",\"namespace_id\": \"$SUBGROUP_ID\",\"path\": \"vkpr_aws_eks\",\"initialize_with_readme\": \"false\"}" \
      https://$GITLAB_URL/api/v4/projects
    )
    debug "CREATE_REPO=$CREATE_REPO"
  else
    CREATE_REPO=$(curl -sX POST -w "%{http_code}" -o /dev/null \
      -H "Content-Type: application/json" -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
      -d "{\"name\": \"vkpr_aws_eks\",\"path\": \"vkpr_aws_eks\",\"initialize_with_readme\": \"false\"}" \
      https://$GITLAB_URL/api/v4/projects
    )
    debug "CREATE_REPO=$CREATE_REPO"
  fi

  case $CREATE_REPO in
    201)
      info "Repository ${PROJECT_LOCATION_PATH:-$GITLAB_USERNAME}/vkpr_aws_eks created"
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
    $VKPR_JQ -r ".[] | select(.name==\"vkpr_aws_eks\").id"
  )

  if [[ $PROJECT_LOCATION == "groups" ]]; then
    PROJECT_IDENTIFIER=$REPO_ID
    PROJECT_DESTINATION=$PROJECT_LOCATION_PATH
  else
    PROJECT_IDENTIFIER=$(rawUrlEncode "${GITLAB_USERNAME}/vkpr_aws_eks")
    PROJECT_DESTINATION=$GITLAB_USERNAME
  fi

  debug "PROJECT_IDENTIFIER=$PROJECT_IDENTIFIER"
  debug "PROJECT_DESTINATION=$PROJECT_DESTINATION"
}

cloneRepository() {
  git clone -q https://gitlab.com/vkpr/aws-eks.git "$VKPR_HOME"/tmp/aws-eks
  cd "$VKPR_HOME"/tmp/aws-eks || exit
  git remote remove origin
  git remote add origin https://$GITLAB_USERNAME:$GITLAB_TOKEN@$GITLAB_URL/$PROJECT_DESTINATION/vkpr_aws_eks.git
  git checkout -b "$VKPR_ENV_EKS_CLUSTER_NAME"
  configureConfigFile
  configureBackend
  git commit -q -am "[VKPR] Initial configuration defaults.yml"
  git push -q --all
  cd - > /dev/null || exit
  rm -fr "$VKPR_HOME"/tmp/aws-eks
}

configureConfigFile() {
  $VKPR_YQ eval -i "del(.node_groups) |
    .cluster_name = \"$VKPR_ENV_EKS_CLUSTER_NAME\" |
    .cluster_version = \"$VKPR_ENV_EKS_VERSION\" |
    .node_groups.${VKPR_ENV_EKS_CLUSTER_NAME}.desired_capacity = \"$VKPR_ENV_EKS_NODES_QUANTITY_SIZE\" |
    .node_groups.${VKPR_ENV_EKS_CLUSTER_NAME}.max_capacity = \"$(( VKPR_ENV_EKS_NODES_QUANTITY_SIZE + 2 ))\" |
    .node_groups.${VKPR_ENV_EKS_CLUSTER_NAME}.min_capacity = \"$VKPR_ENV_EKS_NODES_QUANTITY_SIZE\" |
    .node_groups.${VKPR_ENV_EKS_CLUSTER_NAME}.ami_type = \"$VKPR_ENV_EKS_AMI_TYPE\" |
    .node_groups.${VKPR_ENV_EKS_CLUSTER_NAME}.instance_types[0] = \"$VKPR_ENV_EKS_NODES_INSTANCE_TYPE\" |
    .node_groups.${VKPR_ENV_EKS_CLUSTER_NAME}.capacity_type = \"${VKPR_ENV_EKS_NODES_CAPACITY_TYPE^^}\"
  " "$VKPR_HOME"/tmp/aws-eks/config/defaults.yml
  mergeVkprValuesExtraArgs "aws.eks" "$VKPR_HOME"/tmp/aws-eks/config/defaults.yml
}

configureBackend() {
  case $VKPR_ENV_EKS_TERRAFORM_STATE in
    gitlab)
      $VKPR_YQ -i ".include[0].remote = \"https://gitlab.com/vkpr/templates/-/raw/main/Full-Workflow-GitLab-Backend.gitlab-ci.yml\" |
        .variables.CI_GITLAB_TOKEN = \"\$CI_GITLAB_TOKEN\"" "$VKPR_HOME"/tmp/aws-eks/.gitlab-ci.yml
    ;;
    s3)
      sed -i "s/http/s3/g" "$VKPR_HOME"/tmp/aws-eks/backend.tf
      $VKPR_YQ -i ".include[0].remote = \"https://gitlab.com/vkpr/templates/-/raw/main/Full-Workflow-S3-Backend.gitlab-ci.yml\" |
        .variables.S3_BUCKET = \"\$S3_BUCKET\" |
        .variables.S3_KEY = \"\$S3_KEY\" |
        .variables.AWS_REGION = \"\$AWS_REGION\"" "$VKPR_HOME"/tmp/aws-eks/.gitlab-ci.yml
    ;;
    terraform_cloud)
      sed -i "s/http/remote/g" "$VKPR_HOME"/tmp/aws-eks/backend.tf
      $VKPR_YQ -i ".include[0].remote = \"https://gitlab.com/vkpr/templates/-/raw/main/Full-Workflow-TerraformCloud-Backend.gitlab-ci.yml\"" "$VKPR_HOME"/tmp/aws-eks/.gitlab-ci.yml
    ;;
  esac
}

setVariablesRepo() {
  createOrUpdateVariable "$PROJECT_IDENTIFIER" "AWS_ACCESS_KEY" "$AWS_ACCESS_KEY" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
  createOrUpdateVariable "$PROJECT_IDENTIFIER" "AWS_SECRET_KEY" "$AWS_SECRET_KEY" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
  createOrUpdateVariable "$PROJECT_IDENTIFIER" "AWS_REGION" "$AWS_REGION" "no" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITLAB_TOKEN"

  case $VKPR_ENV_EKS_TERRAFORM_STATE in
    gitlab)
      createOrUpdateVariable "$PROJECT_IDENTIFIER" "CI_GITLAB_TOKEN" "$GITLAB_TOKEN" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
    ;;
    s3)
      createOrUpdateVariable "$PROJECT_IDENTIFIER" "S3_BUCKET" "$S3_BUCKET" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
      createOrUpdateVariable "$PROJECT_IDENTIFIER" "S3_KEY" "$S3_KEY" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
    ;;
    terraform_cloud)
      createOrUpdateVariable "$PROJECT_IDENTIFIER" "TF_CLOUD_TOKEN" "$TF_CLOUD_TOKEN" "yes" "$VKPR_ENV_EKS_CLUSTER_NAME" "$GITLAB_TOKEN"
    ;;
  esac
}


createRepo
cloneRepository
setVariablesRepo
