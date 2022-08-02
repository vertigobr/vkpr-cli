#!/usr/bin/env bash

runFormula() {
  local PROJECT_ID PIPELINE_ID DEPLOY_STATUS;

  validateGitlabUsername "$GITLAB_USERNAME"
  validateGitlabToken "$GITLAB_TOKEN"

  PROJECT_ID=$(curl -s https://gitlab.com/api/v4/users/"$GITLAB_USERNAME"/projects |\
    $VKPR_JQ ".[] | select(.name == \"k8s-digitalocean\").id"
  )
  PIPELINE_ID=$(curl -s https://gitlab.com/api/v4/projects/"$PROJECT_ID"/pipelines \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" |\
    $VKPR_JQ '.[0].id'
  )
  DEPLOY_STATUS=$(curl -s https://gitlab.com/api/v4/projects/"$PROJECT_ID"/pipelines/"$PIPELINE_ID"/jobs \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" |\
    $VKPR_JQ -r '.[1].status'
  )

  jobDestroyCluster "$PROJECT_ID" "$PIPELINE_ID" "$DEPLOY_STATUS" "$GITLAB_TOKEN"
}
