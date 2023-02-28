#!/usr/bin/env bash

runFormula() {
  local PROJECT_ID PIPELINE_ID BUILD_COMPLETE;

  validateGitlabUsername "$GITLAB_USERNAME"
  validateGitlabToken "$GITLAB_TOKEN"

  PROJECT_ID=$(curl -s https://gitlab.com/api/v4/users/"$GITLAB_USERNAME"/projects |\
    $VKPR_JQ '.[] | select(.name == "k8s-digitalocean").id'
  )
  debug "PROJECT_ID=$PROJECT_ID"

  PIPELINE_ID=$(curl -s https://gitlab.com/api/v4/projects/"$PROJECT_ID"/pipelines \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" |\
    $VKPR_JQ '.[0].id'
  )
  debug "PIPELINE_ID=$PIPELINE_ID"

  BUILD_COMPLETE=$(curl -s https://gitlab.com/api/v4/projects/"$PROJECT_ID"/pipelines/"$PIPELINE_ID"/jobs \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" |\
    $VKPR_JQ -r '.[] | select(.name == "build").status'
  )
  debug "BUILD_COMPLETE=$BUILD_COMPLETE"

  waitJobComplete "$PROJECT_ID" "$PIPELINE_ID" "$BUILD_COMPLETE" "$GITLAB_TOKEN" "build"
  jobDeployCluster "$PROJECT_ID" "$PIPELINE_ID" "$BUILD_COMPLETE" "$GITLAB_TOKEN"
}
