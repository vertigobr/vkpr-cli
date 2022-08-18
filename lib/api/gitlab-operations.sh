#!/usr/bin/env bash

## Create a new variable setting cluster-name as environment
## If var already exist, just update your value
# Parameters:
# 1 - PROJECT_ENCODED
# 2 - PARAMETER_KEY
# 3 - PARAMETER_VALUE
# 4 - PARAMETER_MASKED
# 5 - ENVIRONMENT_SCOPE
# 6 - GITLAB_TOKEN
createOrUpdateVariable(){
  local PROJECT_ENCODED="$1" PARAMETER_KEY="$2" PARAMETER_VALUE="$3" \
        PARAMETER_MASKED="$4" ENVIRONMENT_SCOPE="$5" GITLAB_TOKEN="$6"
  local VARIABLE_RESPONSE_CODE

  # Documentation: https://docs.gitlab.com/ee/api/project_level_variables.html#create-variable
  VARIABLE_RESPONSE_CODE=$(curl -siX POST -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "https://gitlab.com/api/v4/projects/${PROJECT_ENCODED}/variables" \
    --form "key=$PARAMETER_KEY" \
    --form "value=$PARAMETER_VALUE" \
    --form "masked=$PARAMETER_MASKED" |\
    head -n 1 |\
    awk -F' ' '{print $2}'
  )
  debug "VARIABLE_RESPONSE_CODE = $VARIABLE_RESPONSE_CODE"

  case $VARIABLE_RESPONSE_CODE in
    201)
      warn "Variable $PARAMETER_KEY created into ${EKS_CLUSTER_NAME} environment"
      ;;
    400)
      warn "Variable $PARAMETER_KEY already exists, updating..."
      updateVariable "$@"
      ;;
    401)
      error "Unauthorized access to GitLab API"
      exit 1
      ;;
    *)
      error "Something wrong while saving $PARAMETER_KEY"
      ;;
  esac
}

## Update gitlab variable
# Parameters:
# 1 - PROJECT_ENCODED
# 2 - PARAMETER_KEY
# 3 - PARAMETER_VALUE
# 4 - PARAMETER_MASKED
# 5 - ENVIRONMENT_SCOPE
# 6 - GITLAB_TOKEN
updateVariable(){
  local PROJECT_ENCODED="$1" \
        PARAMETER_KEY="$2" \
        PARAMETER_VALUE="$3" \
        PARAMETER_MASKED="$4" \
        ENVIRONMENT_SCOPE="$5" \
        GITLAB_TOKEN="$6"

  local UPDATE_CODE

  # Documentation: https://docs.gitlab.com/ee/api/project_level_variables.html#update-variable
  UPDATE_CODE=$(curl -siX PUT -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "https://gitlab.com/api/v4/projects/${PROJECT_ENCODED}/variables/${PARAMETER_KEY}" \
    --form "value=$PARAMETER_VALUE" \
    --form "masked=$PARAMETER_MASKED" |\
    head -n 1 |\
    awk -F' ' '{print $2}'
  )
  debug "UPDATE_CODE= $UPDATE_CODE"

  if [ "$UPDATE_CODE" == "200" ];then
    info "$PARAMETER_KEY updated"
  else
    error "error while updating $PARAMETER_KEY, $UPDATE_CODE"
  fi
}

# -----------------------------------------------------------------------------
# Pipeline's Jobs functions
# -----------------------------------------------------------------------------

waitJobComplete(){
  local PROJECT_ID="$1" \
        PIPELINE_ID="$2" \
        JOB_COMPLETE="$3" \
        GITLAB_TOKEN="$4" \
        JOB_TYPE="$5"

  SECONDS=0
  while [[ "$JOB_COMPLETE" != "success" ]]; do
    [[ "$JOB_COMPLETE" == "failed" ]] && break
    bold "Job still executing, await more... ${SECONDS}s passed"
    sleep 30
    (( SECONDS + 30 ))
    JOB_COMPLETE=$(curl -s https://gitlab.com/api/v4/projects/"$PROJECT_ID"/pipelines/"$PIPELINE_ID"/jobs \
      -H "PRIVATE-TOKEN: $GITLAB_TOKEN" |\
      $VKPR_JQ -r ".[] | select(.name == \"$JOB_TYPE\").status"
    )
    debug "JOB_COMPLETE=$JOB_COMPLETE"
  done
}

jobDeployCluster(){
  local PROJECT_ID="$1" \
        PIPELINE_ID="$2" \
        BUILD_COMPLETE="$3" \
        GITLAB_TOKEN="$4"

  if [[ "$BUILD_COMPLETE" == "failed" ]]; then
    error "Error in pipeline, review the errors in Gitlab"
    exit
  fi

  local DEPLOY_ID;
  DEPLOY_ID=$(curl -s https://gitlab.com/api/v4/projects/"$PROJECT_ID"/pipelines/"$PIPELINE_ID"/jobs \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" |\
    $VKPR_JQ '.[] | select(.name == "deploy").id'
  )
  debug "DEPLOY_ID=$DEPLOY_ID"

  curl -sX POST https://gitlab.com/api/v4/projects/"$PROJECT_ID"/jobs/"$DEPLOY_ID"/play \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" > /dev/null
  info "Deploy job started successfully"
}

jobDestroyCluster() {
  local PROJECT_ID="$1" \
        PIPELINE_ID="$2" \
        DEPLOY_STATUS="$3" \
        GITLAB_TOKEN="$4"

  if [[ "$DEPLOY_STATUS" != "success" ]]; then
    error "Error in pipeline, review the errors in Gitlab"
    exit
  fi

  DESTROY_ID=$(curl -s https://gitlab.com/api/v4/projects/"$PROJECT_ID"/pipelines/"$PIPELINE_ID"/jobs \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" |\
    $VKPR_JQ '.[] | select(.name == "destroy").id'
  )
  debug "DESTROY_ID=$DESTROY_ID"

  curl -sX POST https://gitlab.com/api/v4/projects/"$PROJECT_ID"/jobs/"$DESTROY_ID"/play \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" > /dev/null
  info "Destroy job started successfully"
}

downloadKubeconfig() {
  local PROJECT_ID="$1" \
        PIPELINE_ID="$2" \
        DEPLOY_COMPLETE="$3" \
        GITLAB_TOKEN="$4" \
        DIR_LOCATION="$5"

  if [[ "$DEPLOY_COMPLETE" == "failed" ]]; then
    error "Error in pipeline, review the errors in Gitlab"
    exit
  fi

  local DEPLOY_ID;
  DEPLOY_ID=$(curl -s https://gitlab.com/api/v4/projects/"$PROJECT_ID"/pipelines/"$PIPELINE_ID"/jobs \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" |\
    $VKPR_JQ '.[] | select(.name == "deploy").id'
  )
  debug "DEPLOY_ID=$DEPLOY_ID"

  curl --location -s https://gitlab.com/api/v4/projects/"$PROJECT_ID"/jobs/"$DEPLOY_ID"/artifacts \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    -o /tmp/artifacts.zip > /dev/null
  unzip -q /tmp/artifacts.zip -d /tmp
  mkdir -p "$VKPR_HOME"/kubeconfig/"$DIR_LOCATION"
  mv /tmp/kube/* "$VKPR_HOME"/kubeconfig/"$DIR_LOCATION"
  rm -r /tmp/artifacts.zip /tmp/kube
}
