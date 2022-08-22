#!/usr/bin/env bash


## List all repository variables
# Parameters:
# 1 - PROJECT_OWNER_AND_REPO - eg: owner/project-name
# 2 - BITBUCKET_USERNAME - bitbucket user
# 3 - BITBUCKET_TOKEN - bitbucket token
bitbucketListRepositoryVariables(){
  local VAR_OWNER_AND_REPO=$1
  local VAR_BITBUCKET_USERNAME=$2
  local VAR_BITBUCKET_TOKEN=$3

  REQUEST=$(curl -sSL -w "|%{http_code}" \
    -H "Accept: application/json" \
    -u "${VAR_BITBUCKET_USERNAME}":"${VAR_BITBUCKET_TOKEN}" \
    "https://api.bitbucket.org/2.0/repositories/${VAR_OWNER_AND_REPO}/pipelines_config/variables/")

  REQUEST_BODY=$(echo $REQUEST | cut -d "|" -f1)
  REQUEST_HTTP_CODE=$(echo $REQUEST | cut -d "|" -f2)

  if [ "${REQUEST_HTTP_CODE}" == "200" ]; then
    ## return json compacted
    echo "$REQUEST_BODY" | jq -c '.'
    return 0
  else
    error "Something wrong while getting parameters from bitbucket"
    exit 13
  fi
}

## Get a repository variable by name
# Parameters:
# 1 - PROJECT_OWNER_AND_REPO - eg: owner/project-name
# 2 - VARIABLE_NAME - eg: VAR_SAMPLE
# 3 - BITBUCKET_USERNAME - bitbucket user
# 4 - BITBUCKET_TOKEN - bitbucket token
bitbucketGetRepositoryVariable(){
  local VAR_OWNER_AND_REPO=$1
  local VAR_VARIAVE_KEY=$2
  local VAR_BITBUCKET_USERNAME=$3
  local VAR_BITBUCKET_TOKEN=$4

  local VARIABLES; VARIABLES=$(bitbucketListRepositoryVariables "$VAR_OWNER_AND_REPO" "$VAR_BITBUCKET_USERNAME" "$VAR_BITBUCKET_TOKEN")
  local VARIABLE; VARIABLE=$(echo "$VARIABLES" | $VKPR_JQ -r ".values[] | select(.key == \"$VAR_VARIAVE_KEY\")")

  if [ -n "$VARIABLE" ];then
    echo "$VARIABLE"
    return 0
  fi
}

## Create variable
# Parameters:
# 1 - PROJECT_OWNER_AND_REPO - eg: owner/project-name
# 2 - VARIABLE_NAME - eg: VAR_SAMPLE
# 3 - VARIABLE_VALUE - eg: abc
# 4 - VARIABLE_SECURED - true or false
# 5 - BITBUCKET_USERNAME - bitbucket user
# 6 - BITBUCKET_TOKEN - bitbucket token
bitbucketCreateRepositoryVariable(){
  local VAR_OWNER_AND_REPO=$1
  local VAR_VARIABLE_KEY=$2
  local VAR_VARIABLE_VALUE=$3
  local VAR_VARIABLE_SECURED=$4
  local VAR_BITBUCKET_USERNAME=$5
  local VAR_BITBUCKET_TOKEN=$6

  local ENVIRONMENT_UUID; ENVIRONMENT_UUID=$(uuidgen)

  curl -s -X POST -u "${VAR_BITBUCKET_USERNAME}":"${VAR_BITBUCKET_TOKEN}" \
    -H 'Content-Type: application/json' \
    -d "{\"type\":\"string\",\"uuid\":\"${ENVIRONMENT_UUID}\",\"key\":\"${VAR_VARIABLE_KEY}\",\"value\":\"${VAR_VARIABLE_VALUE}\",\"secured\":${VAR_VARIABLE_SECURED}}" \
    "https://api.bitbucket.org/2.0/repositories/${VAR_OWNER_AND_REPO}/pipelines_config/variables/" 1> /dev/null && notice "Variable $VAR_VARIABLE_KEY created"
}

## Update a variable
# Parameters:
# 1 - PROJECT_OWNER_AND_REPO - eg: owner/project-name
# 2 - VARIABLE_UUID - eg: uuid
# 3 - VARIABLE_NAME - eg: VAR_SAMPLE
# 4 - VARIABLE_VALUE - eg: abc
# 5 - VARIABLE_SECURED - true or false
# 6 - BITBUCKET_USERNAME - bitbucket user
# 7 - BITBUCKET_TOKEN - bitbucket token
bitbucketUpdateRepositoryVariable(){
  local VAR_OWNER_AND_REPO=$1
  local VAR_VARIABLE_UUID=$2
  local VAR_VARIABLE_KEY=$3
  local VAR_VARIABLE_VALUE=$4
  local VAR_VARIABLE_SECURED=$5
  local VAR_BITBUCKET_USERNAME=$6
  local VAR_BITBUCKET_TOKEN=$7

  curl -s -X PUT -u "${VAR_BITBUCKET_USERNAME}":"${VAR_BITBUCKET_TOKEN}" \
    -H 'Content-Type: application/json' \
    -d "{\"key\":\"${VAR_VARIABLE_KEY}\",\"value\":\"${VAR_VARIABLE_VALUE}\",\"secured\":${VAR_VARIABLE_SECURED}}" \
    "https://api.bitbucket.org/2.0/repositories/${VAR_OWNER_AND_REPO}/pipelines_config/variables/%7B${VAR_VARIABLE_UUID}%7D" 1> /dev/null && notice "Variable $VAR_VARIABLE_KEY updated"
}


## Create or update a variable
## If var already exist, just update your value
# Parameters:
# 1 - PROJECT_OWNER_AND_REPO - eg: owner/project-name
# 2 - VARIABLE_NAME - eg: VAR_SAMPLE
# 3 - VARIABLE_VALUE - eg: abc
# 4 - VARIABLE_SECURED - true or false
# 5 - BITBUCKET_USERNAME - bitbucket user
# 6 - BITBUCKET_TOKEN - bitbucket token
bitbucketCreateOrUpdateRepositoryVariable(){
  local VAR_OWNER_AND_REPO=$1
  local VAR_VARIABLE_KEY=$2
  local VAR_VARIABLE_VALUE=$3
  local VAR_VARIABLE_SECURED=$4
  local VAR_BITBUCKET_USERNAME=$5
  local VAR_BITBUCKET_TOKEN=$6

  local VARIABLE; VARIABLE=$(bitbucketGetRepositoryVariable "$VAR_OWNER_AND_REPO" "$VAR_VARIABLE_KEY" "$VAR_BITBUCKET_USERNAME" "$VAR_BITBUCKET_TOKEN")
  if [ -z "$VARIABLE" ];then
    debug "create"
    bitbucketCreateRepositoryVariable "$VAR_OWNER_AND_REPO" "$VAR_VARIABLE_KEY" "$VAR_VARIABLE_VALUE" "$VAR_VARIABLE_SECURED" "$VAR_BITBUCKET_USERNAME" "$VAR_BITBUCKET_TOKEN"
  else
    debug "update"
    local VARIABLE_UUID; VARIABLE_UUID=$(echo "$VARIABLE" | $VKPR_JQ -r ".uuid" | sed 's/\({\|\}\)//g')
    debug "VARIABLE_UUID=$VARIABLE_UUID"
    bitbucketUpdateRepositoryVariable "$VAR_OWNER_AND_REPO" "$VARIABLE_UUID" "$VAR_VARIABLE_KEY" "$VAR_VARIABLE_VALUE" "$VAR_VARIABLE_SECURED" "$VAR_BITBUCKET_USERNAME" "$VAR_BITBUCKET_TOKEN"
  fi
}
