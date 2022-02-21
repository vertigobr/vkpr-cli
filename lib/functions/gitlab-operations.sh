
## Create a new variable setting cluster-name as environment
## If var already exist, just update your value
# Parameters:
# 1 - PROJECT_ID
# 2 - PARAMETER_KEY
# 3 - PARAMETER_VALUE
# 4 - PARAMETER_MASKED
# 5 - ENVIRONMENT_SCOPE
# 6 - GITLAB_TOKEN
createOrUpdateVariable(){
  local PROJECT_ID=$1
  local PARAMETER_KEY=$2
  local PARAMETER_VALUE=$3
  local PARAMETER_MASKED=$4
  local ENVIRONMENT_SCOPE=$5
  local GITLAB_TOKEN=$6
  
  # Documentation: https://docs.gitlab.com/ee/api/project_level_variables.html#create-variable
  local VARIABLE_RESPONSE_CODE=$(curl -s -i --request POST --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "https://gitlab.com/api/v4/projects/${PROJECT_ID}/variables" \
    --form "key=$PARAMETER_KEY" --form "value=$PARAMETER_VALUE" --form "masked=$PARAMETER_MASKED" --form "environment_scope=$ENVIRONMENT_SCOPE"  | head -n 1 | awk -F' ' '{print $2}')
  # echo "VARIABLE_RESPONSE_CODE = $VARIABLE_RESPONSE_CODE"

  if [ $VARIABLE_RESPONSE_CODE = 201 ];then
    echoColor yellow "Variable $PARAMETER_KEY created into ${EKS_CLUSTER_NAME} environment"
  elif [ $VARIABLE_RESPONSE_CODE = 400 ];then
    # echoColor yellow "Variable $PARAMETER_KEY already exists, updating..."
    updateVariable $@
  elif [ $VARIABLE_RESPONSE_CODE = 401 ];then
    echoColor red "Unauthorized access to GitLab API"
    exit 1
  else
    echoColor red "Something wrong while saving $PARAMETER_KEY"
  fi
    
}


## Update gitlab variable
# Parameters:
# 1 - PROJECT_ID
# 2 - PARAMETER_KEY
# 3 - PARAMETER_VALUE
# 4 - PARAMETER_MASKED
# 5 - ENVIRONMENT_SCOPE
# 6 - GITLAB_TOKEN
updateVariable(){
  local PROJECT_ID=$1
  local PARAMETER_KEY=$2
  local PARAMETER_VALUE=$3
  local PARAMETER_MASKED=$4
  local ENVIRONMENT_SCOPE=$5
  local GITLAB_TOKEN=$6

  # Documentation: https://docs.gitlab.com/ee/api/project_level_variables.html#update-variable
  local UPDATE_CODE=$(curl -s -i --request PUT --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "https://gitlab.com/api/v4/projects/${PROJECT_ID}/variables/${PARAMETER_KEY}?filter\[environment_scope\]=${ENVIRONMENT_SCOPE}" \
    --form "value=$PARAMETER_VALUE" --form "masked=$PARAMETER_MASKED" | head -n 1 | awk -F' ' '{print $2}')
  # echo "UPDATE_CODE= $UPDATE_CODE"  
  if [ $UPDATE_CODE = 200 ];then
    echoColor green "$PARAMETER_KEY updated"
  else
    echoColor red "error while updating $PARAMETER_KEY, $UPDATE_CODE"
  fi
}


## Create a new branch using eks-cluster-name as branch's name, or just start a new pipeline
# Parameters:
# 1 - PROJECT_ID
# 2 - BRANCH_NAME
# 3 - GITLAB_TOKEN
createBranch(){
  local PROJECT_ID=$1
  local BRANCH_NAME=$2
  local GITLAB_TOKEN=$3

  echoColor green "Creating branch named $BRANCH_NAME or justing starting a new pipeline"
  # echo "https://gitlab.com/api/v4/projects/${PROJECT_ID}/repository/branches?branch=$1&ref=master"
  
  # Documentation: https://docs.gitlab.com/ee/api/branches.html#create-repository-branch
  local CREATE_BRANCH_CODE=$(curl -s -i --request POST --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "https://gitlab.com/api/v4/projects/${PROJECT_ID}/repository/branches?branch=$BRANCH_NAME&ref=master" | head -n 1 | awk -F' ' '{print $2}')
  # echo "CREATE_BRANCH_CODE: $CREATE_BRANCH_CODE"
  
  if [ $CREATE_BRANCH_CODE = 400 ];then
    createPipeline $@
  fi
}

## create a new pipeline
createPipeline(){
  local PROJECT_ID=$1
  local BRANCH_NAME=$2
  local GITLAB_TOKEN=$3
  # Documentation: https://docs.gitlab.com/ee/api/pipelines.html#create-a-new-pipeline
  local RESPONSE_PIPE=$(curl -s --request POST --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "https://gitlab.com/api/v4/projects/${PROJECT_ID}/pipeline?ref=$BRANCH_NAME")
  # echo "RESPONSE_PIPE: $RESPONSE_PIPE"
  echoColor green "Pipeline url: $(echo $RESPONSE_PIPE | $VKPR_JQ -r '.web_url')"
}
