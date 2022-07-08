#!/bin/bash

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
    --form "masked=$PARAMETER_MASKED" \
    --form "environment_scope=$ENVIRONMENT_SCOPE" |\
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
    "https://gitlab.com/api/v4/projects/${PROJECT_ENCODED}/variables/${PARAMETER_KEY}?filter\[environment_scope\]=${ENVIRONMENT_SCOPE}" \
    --form "value=$PARAMETER_VALUE" \
    --form "masked=$PARAMETER_MASKED" |\
    head -n 1 |\
    awk -F' ' '{print "$2"}'
  )
  debug "UPDATE_CODE= $UPDATE_CODE"

  if [ "$UPDATE_CODE" == "200" ];then
    info "$PARAMETER_KEY updated"
  else
    error "error while updating $PARAMETER_KEY, $UPDATE_CODE"
  fi
}


## Create a new branch using eks-cluster-name as branch's name, or just start a new pipeline
# Parameters:
# 1 - PROJECT_ENCODED
# 2 - BRANCH_NAME
# 3 - GITLAB_TOKEN
createBranch(){
  local PROJECT_ENCODED="$1" \
        BRANCH_NAME="$2" \
        GITLAB_TOKEN="$3"

  local CREATE_BRANCH_CODE

  info "Creating branch named $BRANCH_NAME or justing starting a new pipeline"
  debug "https://gitlab.com/api/v4/projects/${PROJECT_ID}/repository/branches?branch="$1"&ref=master"

  # Documentation: https://docs.gitlab.com/ee/api/branches.html#create-repository-branch
  CREATE_BRANCH_CODE=$(curl -siX POST -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "https://gitlab.com/api/v4/projects/${PROJECT_ENCODED}/repository/branches?branch=$BRANCH_NAME&ref=master" |\
    head -n 1 |\
    awk -F' ' '{print "$2"}'
  )
  debug "CREATE_BRANCH_CODE: $CREATE_BRANCH_CODE"

  if [ "$CREATE_BRANCH_CODE" == "400" ];then
    createPipeline "$@"
  fi
}

## Create a new pipeline
# Parameters:
# 1 - PROJECT_ENCODED
# 2 - BRANCH_NAME
# 3 - GITLAB_TOKEN
createPipeline(){
  local PROJECT_ENCODED="$1" \
        BRANCH_NAME="$2" \
        GITLAB_TOKEN="$3"

  local RESPONSE_PIPE

  # Documentation: https://docs.gitlab.com/ee/api/pipelines.html#create-a-new-pipeline
  RESPONSE_PIPE=$(curl -sX POST -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "https://gitlab.com/api/v4/projects/${PROJECT_ENCODED}/pipeline?ref=$BRANCH_NAME"
  )
  debug "RESPONSE_PIPE: $RESPONSE_PIPE"

  info "Pipeline url: $(echo "$RESPONSE_PIPE" | $VKPR_JQ -r '.web_url')"
}

# -----------------------------------------------------------------------------
# Pipeline's Jobs functions
# -----------------------------------------------------------------------------

waitJobComplete(){
  local PROJECT_ID="$1" \
        PIPELINE_ID="$2" \
        JOB_COMPLETE="$3" \
        GITLAB_TOKEN="$4" \
        JOB_TYPE="$5" # 0- Destroy | 1- Deploy | 2- Build | 3- Validate | 4- Init

  SECONDS=0
  while [[ "$JOB_COMPLETE" != "success" ]]; do
    [[ "$JOB_COMPLETE" == "failed" ]] && break
    bold "Job still executing, await more... ${SECONDS}s passed"
    sleep 30
    (( SECONDS + 30 ))
    JOB_COMPLETE=$(curl -s https://gitlab.com/api/v4/projects/"$PROJECT_ID"/pipelines/"$PIPELINE_ID"/jobs \
      -H "PRIVATE-TOKEN: $GITLAB_TOKEN" |\
      $VKPR_JQ -r ".[$JOB_TYPE].status"
    )
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
    $VKPR_JQ '.[1].id'
  )

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
    $VKPR_JQ '.[0].id'
  )
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
    $VKPR_JQ '.[1].id'
  )

  curl --location -s https://gitlab.com/api/v4/projects/"$PROJECT_ID"/jobs/"$DEPLOY_ID"/artifacts \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    -o /tmp/artifacts.zip > /dev/null
  unzip -q /tmp/artifacts.zip -d /tmp
  mkdir -p "$VKPR_HOME"/kubeconfig/"$DIR_LOCATION"
  mv /tmp/kube/* "$VKPR_HOME"/kubeconfig/"$DIR_LOCATION"
  rm -r /tmp/artifacts.zip /tmp/kube
}
