#!/usr/bin/env bash

runFormula() {
  local PROJECT_ID BRANCH_NAME PIPELINE_ID DEPLOY_COMPLETE;

  validateGitlabUsername "$GITLAB_USERNAME"
  validateGitlabToken "$GITLAB_TOKEN"

  PROJECT_ID=$(curl -s https://gitlab.com/api/v4/users/"$GITLAB_USERNAME"/projects |\
    $VKPR_JQ '.[] | select(.name == "aws-eks").id'
  )
  debug "PROJECT_ID=$PROJECT_ID"

  PIPELINE_ID=$(curl -s https://gitlab.com/api/v4/projects/"$PROJECT_ID"/pipelines \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" |\
    $VKPR_JQ '.[0].id'
  )
  debug "PIPELINE_ID=$PIPELINE_ID"

  BRANCH_NAME=$(curl -s https://gitlab.com/api/v4/projects/"$PROJECT_ID"/pipelines \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" |\
    $VKPR_JQ -r '.[0].ref'
  )
  debug "BRANCH_NAME=$BRANCH_NAME"

  DEPLOY_COMPLETE=$(curl -s https://gitlab.com/api/v4/projects/"$PROJECT_ID"/pipelines/"$PIPELINE_ID"/jobs \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" |\
    $VKPR_JQ -r '.[] | select(.name == "deploy").status'
  )
  debug "DEPLOY_COMPLETE=$DEPLOY_COMPLETE"

  waitJobComplete "$PROJECT_ID" "$PIPELINE_ID" "$DEPLOY_COMPLETE" "$GITLAB_TOKEN" "deploy"
  downloadKubeconfig "$PROJECT_ID" "$PIPELINE_ID" "$DEPLOY_COMPLETE" "$GITLAB_TOKEN" "aws-eks"

  info "Kubeconfig downloaded succefully, located at \$HOME/.vkpr/kubeconfig/aws-eks"
}
