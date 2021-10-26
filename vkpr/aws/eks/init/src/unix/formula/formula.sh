#!/bin/sh

PROJECT_ID=$(rawUrlEncode "$GITLAB_USERNAME/aws-eks")

runFormula() {
  #getting real instance type
  EKS_CLUSTER_NODE_INSTANCE_TYPE=${EKS_CLUSTER_NODE_INSTANCE_TYPE// ([^)]*)/}
  EKS_CLUSTER_NODE_INSTANCE_TYPE=${EKS_CLUSTER_NODE_INSTANCE_TYPE// /}

  checkGlobalConfig $AWS_REGION "us-east-1" "aws.eks.region" "AWS_REGION"
  checkGlobalConfig $EKS_CLUSTER_NAME "eks-sample" "aws.eks.cluster_name" "EKS_CLUSTER_NAME"
  checkGlobalConfig $EKS_CLUSTER_NODE_INSTANCE_TYPE "t3.small" "aws.eks.nodes.instace_type" "EKS_CLUSTER_NODE_INSTANCE_TYPE"
  checkGlobalConfig $EKS_K8S_VERSION "1.21" "aws.eks.version" "EKS_K8S_VERSION"
  checkGlobalConfig $EKS_CLUSTER_SIZE "1" "aws.eks.nodes.size" "EKS_CLUSTER_SIZE"

  local FORK_RESPONSE_CODE=$(curl -s -i -X POST --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "https://gitlab.com/api/v4/projects/$(rawUrlEncode "vkpr/aws-eks")/fork" | head -n 1 | awk -F' ' '{print $2}')
  # echo "FORK_RESPONSE_CODE= $FORK_RESPONSE_CODE"
  if [ $FORK_RESPONSE_CODE = 409 ];then
    echoColor yellow "Project already forked"
  fi
  
  setVariablesGLAB

  createBranch $EKS_CLUSTER_NAME

}

## Set all input into Gitlab environments
setVariablesGLAB() {
  createOrUpdateVariable "AWS_ACCESS_KEY" $AWS_ACCESS_KEY "yes"
  createOrUpdateVariable "AWS_SECRET_KEY" $AWS_SECRET_KEY "yes"
  createOrUpdateVariable "AWS_REGION" $AWS_REGION "no"
  createOrUpdateVariable "EKS_CLUSTER_NAME" $EKS_CLUSTER_NAME "no"
  createOrUpdateVariable "EKS_CLUSTER_NODE_INSTANCE_TYPE" $EKS_CLUSTER_NODE_INSTANCE_TYPE "no"
  createOrUpdateVariable "EKS_K8S_VERSION" "$EKS_K8S_VERSION" "no"
  createOrUpdateVariable "EKS_CLUSTER_SIZE" "$EKS_CLUSTER_SIZE" "no"
}

## Create a new variable setting cluster-name as environment
## If var already exist, just update your value
createOrUpdateVariable(){
  # echo "VARIABLE $1 = $2"
  local VARIABLE_RESPONSE_CODE=$(curl -s -i --request POST --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "https://gitlab.com/api/v4/projects/${PROJECT_ID}/variables" \
    --form "key=$1" --form "value=$2" --form "masked=$3" --form "environment_scope=$EKS_CLUSTER_NAME"  | head -n 1 | awk -F' ' '{print $2}')
  # echo "VARIABLE_RESPONSE_CODE = $VARIABLE_RESPONSE_CODE"

  if [ $VARIABLE_RESPONSE_CODE = 201 ];then
    echoColor yellow "Variable $1 created into ${EKS_CLUSTER_NAME} environment"
  elif [ $VARIABLE_RESPONSE_CODE = 400 ];then
    # echoColor yellow "Variable $1 already exists, updating..."
    updateVariable $@
  else
    echoColor red "Something wrong while saving $1"
  fi
    
}

## Update gitlab variable
updateVariable(){
  local UPDATE_CODE=$(curl -s -i --request PUT --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "https://gitlab.com/api/v4/projects/${PROJECT_ID}/variables/${1}?filter\[environment_scope\]=${EKS_CLUSTER_NAME}" \
    --form "value=$2" --form "masked=$3" | head -n 1 | awk -F' ' '{print $2}')
  # echo "UPDATE_CODE= $UPDATE_CODE"  
  if [ $UPDATE_CODE = 200 ];then
    echoColor green "$1 updated"
  else
    echoColor red "error while updating $1, $UPDATE_CODE"
  fi
}

## Create a new branch using eks-cluster-name as branch's name, or just start a new pipeline
createBranch(){
  echoColor green "Creating branch named $1 or justing starting a new pipeline"
  # echo "https://gitlab.com/api/v4/projects/${PROJECT_ID}/repository/branches?branch=$1&ref=master"
  local CREATE_BRANCH_CODE=$(curl -s -i --request POST --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "https://gitlab.com/api/v4/projects/${PROJECT_ID}/repository/branches?branch=$1&ref=master" | head -n 1 | awk -F' ' '{print $2}')
  # echo "CREATE_BRANCH_CODE: $CREATE_BRANCH_CODE"
  
  if [ $CREATE_BRANCH_CODE = 400 ];then
    createPipeline $1
  fi
}

## create a new pipeline
createPipeline(){
  RESPONSE_PIPE=$(curl -s --request POST --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "https://gitlab.com/api/v4/projects/${PROJECT_ID}/pipeline?ref=$1")
  # echo "RESPONSE_PIPE: $RESPONSE_PIPE"
  echoColor green "Pipeline url: $(echo $RESPONSE_PIPE | $VKPR_JQ -r '.web_url')"
}