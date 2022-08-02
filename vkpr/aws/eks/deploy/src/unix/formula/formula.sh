#!/usr/bin/env bash

runFormula() {
  local PROJECT_ID PIPELINE_ID BUILD_COMPLETE;

  validateGitlabUsername "$GITLAB_USERNAME"
  validateGitlabToken "$GITLAB_TOKEN"

  PROJECT_ID=$(curl -s https://gitlab.com/api/v4/users/"$GITLAB_USERNAME"/projects |\
    $VKPR_JQ '.[] | select(.name == "aws-eks").id'
  )
  PIPELINE_ID=$(curl -s https://gitlab.com/api/v4/projects/"$PROJECT_ID"/pipelines \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" |\
    $VKPR_JQ '.[0].id'
  )
  BUILD_COMPLETE=$(curl -s https://gitlab.com/api/v4/projects/"$PROJECT_ID"/pipelines/"$PIPELINE_ID"/jobs \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" |\
    $VKPR_JQ -r '.[2].status'
  )

  waitJobComplete "$PROJECT_ID" "$PIPELINE_ID" "$BUILD_COMPLETE" "$GITLAB_TOKEN" "2"
  jobDeployCluster "$PROJECT_ID" "$PIPELINE_ID" "$BUILD_COMPLETE" "$GITLAB_TOKEN"
}
