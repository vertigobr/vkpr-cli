#!/usr/bin/env bash

runFormula() {
  local PROJECT_ID PIPELINE_ID DEPLOY_STATUS;

  validateGitlabUsername "$GITLAB_USERNAME"
  validateGitlabToken "$GITLAB_TOKEN"

  PROJECT_ID=$(curl -s https://gitlab.com/api/v4/users/"$GITLAB_USERNAME"/projects |\
    $VKPR_JQ ".[] | select(.name == \"aws-eks\").id"
  )
  debug "PROJECT_ID=$PROJECT_ID"

  PIPELINE_ID=$(curl -s https://gitlab.com/api/v4/projects/"$PROJECT_ID"/pipelines \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" |\
    $VKPR_JQ '.[0].id'
  )
  debug "PIPELINE_ID=$PIPELINE_ID"

  DEPLOY_STATUS=$(curl -s https://gitlab.com/api/v4/projects/"$PROJECT_ID"/pipelines/"$PIPELINE_ID"/jobs \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" |\
    $VKPR_JQ -r '.[] | select(.name == "deploy").status'
  )
  debug "DEPLOY_STATUS=$DEPLOY_STATUS"

  jobDestroyCluster "$PROJECT_ID" "$PIPELINE_ID" "$DEPLOY_STATUS" "$GITLAB_TOKEN"
}
