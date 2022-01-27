#!/bin/bash

runFormula() {
  PROJECT_ID=$(rawUrlEncode "$GITLAB_USERNAME/${PROJECT_NAME}")
  echoColor blue "Creating new parameter ${PARAMETER_NAME}"
  # echo "Hello World! ${PROJECT_ID}"
  # echo ${PROJECT_NAME}
  # echo ${PARAMETER_NAME}
  # echo ${PARAMETER_VALUE}
  # echo ${PARAMETER_MASKED}
  # echo ${ENVIRONMENT_SCOPE}
  # echo $(cat ./utils/gitlab-parameter-operations.sh)
  createOrUpdateVariable $PROJECT_ID $PARAMETER_NAME $PARAMETER_VALUE $PARAMETER_MASKED $ENVIRONMENT_SCOPE $GITLAB_TOKEN
}
 