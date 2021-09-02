#!/bin/sh

runFormula() {
  PROJECT_ID=$(curl https://gitlab.com/api/v4/users/$GITLAB_USERNAME/projects | jq '.[0] | .id')
  DESTROY_ID=$(curl -H "PRIVATE-TOKEN: $GITLAB_TOKEN" https://gitlab.com/api/v4/projects/$PROJECT_ID/jobs | jq '.[0] | .id')
  curl -H "PRIVATE-TOKEN: $GITLAB_TOKEN" -X POST -s https://gitlab.com/api/v4/projects/$PROJECT_ID/jobs/$DESTROY_ID/play > /dev/null
}