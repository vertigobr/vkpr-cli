#!/bin/bash

runFormula() {
  PROJECT_ID=$(rawUrlEncode "${PROJECT_NAME}")
  echoColor blue "Creating new parameter ${PARAMETER_NAME}"
  
  ## seting '*' as default value for PARAMETER_SCOPE
  createOrUpdateVariable $PROJECT_ID $PARAMETER_NAME $PARAMETER_VALUE $PARAMETER_MASKED ${PARAMETER_SCOPE:-\*} $GITLAB_TOKEN
}
 