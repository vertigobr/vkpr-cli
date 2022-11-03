#!/usr/bin/env bash

createRepo() {
  if [ $PROJECT_LOCATION == "groups" ]; then
    CREATE_REPO=$(curl -sX POST -w "%{http_code}" -o /dev/null \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -d "{\"name\": \"vkpr_aws_eks\",\"homepage\":\"https://github.com\",\"visibility\": \"private\"}" \
      https://api.github.com/orgs/$PROJECT_LOCATION_PATH/repos
    )
    debug "CREATE_REPO=$CREATE_REPO"
  else
    CREATE_REPO=$(curl -sX POST -w "%{http_code}" -o /dev/null \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -d "{\"name\": \"vkpr_aws_eks\",\"homepage\":\"https://github.com\",\"visibility\": \"private\"}" \
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
  git clone -q https://gitlab.com/vkpr/aws-eks.git "$VKPR_HOME"/tmp/aws-eks
  cd "$VKPR_HOME"/tmp/aws-eks || exit
  git remote remove origin
  git remote add origin https://$GITHUB_USERNAME:$GITHUB_TOKEN@github.com/${PROJECT_NAME}.git
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
    s3)
      sed -i "s/http/s3/g" "$VKPR_HOME"/tmp/aws-eks/backend.tf
    ;;
    terraform_cloud)
      sed -i "s/http/remote/g" "$VKPR_HOME"/tmp/aws-eks/backend.tf
    ;;
  esac
}

setVariablesRepo() {
  PUBLIC_KEY=$(githubActionsGetPublicKey "$PROJECT_NAME" "$GITHUB_USERNAME" "$GITHUB_TOKEN")
  debug "PUBLIC_KEY=$PUBLIC_KEY"

  githubActionsCreateUpdateSecret "$PROJECT_NAME" "AWS_ACCESS_KEY" "$AWS_ACCESS_KEY" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
  githubActionsCreateUpdateSecret "$PROJECT_NAME" "AWS_SECRET_KEY" "$AWS_SECRET_KEY" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
  githubActionsCreateUpdateSecret "$PROJECT_NAME" "AWS_REGION" "$AWS_REGION" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"

  case $VKPR_ENV_EKS_TERRAFORM_STATE in
    s3)
      githubActionsCreateUpdateSecret "$PROJECT_NAME" "S3_BUCKET" "$S3_BUCKET" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
      githubActionsCreateUpdateSecret "$PROJECT_NAME" "S3_KEY" "$S3_KEY" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
    ;;
    terraform_cloud)
      githubActionsCreateUpdateSecret "$PROJECT_NAME" "TF_CLOUD_TOKEN" "$TF_CLOUD_TOKEN" "$PUBLIC_KEY" "$GITHUB_USERNAME" "$GITHUB_TOKEN"
    ;;
  esac
}

[ $PROJECT_LOCATION == "groups" ] && PROJECT_NAME="$PROJECT_LOCATION_PATH/vkpr_aws_eks" || PROJECT_NAME="$GITHUB_USERNAME/vkpr_aws_eks"
debug "PROJECT_NAME=$PROJECT_NAME"

createRepo
cloneRepository
setVariablesRepo
