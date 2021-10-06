#!/bin/sh

runFormula() {
  PROJECT_ID=$(curl https://gitlab.com/api/v4/users/$GITLAB_USERNAME/projects | $VKPR_JQ '.[0] | .id')
  destroyEKS
}

destroyEKS() {
  DESTROY_ID=$(curl -H "PRIVATE-TOKEN: $GITLAB_TOKEN" https://gitlab.com/api/v4/projects/$PROJECT_ID/jobs | $VKPR_JQ '.[0] | .id')
  curl -H "PRIVATE-TOKEN: $GITLAB_TOKEN" -X POST -s https://gitlab.com/api/v4/projects/$PROJECT_ID/jobs/$DESTROY_ID/play > /dev/null
}