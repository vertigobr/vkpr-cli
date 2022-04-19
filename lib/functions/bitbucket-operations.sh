#!/bin/bash


## List all repository variables
# Parameters:
# 1 - PROJECT_OWNER_AND_REPO - eg: owner/project-name
# 2 - BITBUCKET_USERNAME - bitbucket user
# 3 - BITBUCKET_TOKEN - bitbucket token
bitbucketListRepositoryVariables(){
    local VAR_OWNER_AND_REPO=$1
    local VAR_BITBUCKET_USERNAME=$2
    local VAR_BITBUCKET_TOKEN=$3
    
    {
        IFS= read -rd '' BODY
        IFS= read -rd '' HTTP_CODE
        IFS= read -rd '' STATUS
    } < <({ out=$(curl -sSL -o /dev/stderr -w "%{http_code}" -H "Accept: application/json" -u ${VAR_BITBUCKET_USERNAME}:${VAR_BITBUCKET_TOKEN} "https://api.bitbucket.org/2.0/repositories/${VAR_OWNER_AND_REPO}/pipelines_config/variables/"); } 2>&1; printf '\0%s' "$out" "$?")
    
    if [ "${HTTP_CODE}" == "200" ]; then
        ## return json compacted
        echo "$BODY" | jq -c '.'
        return 0
    else
        echoColor red "Something wrong while getting parameters from bitbucket"
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

    local VARIABLES=$(bitbucketListRepositoryVariables $VAR_OWNER_AND_REPO $VAR_BITBUCKET_USERNAME $VAR_BITBUCKET_TOKEN)
    local VARIABLE=$(echo $VARIABLES | jq -r '.values[] | select(.key == "'$VAR_VARIAVE_KEY'")')
    
    if [ ! -z "$VARIABLE" ];then
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
    
    local ENVIRONMENT_UUID=$(uuidgen)
    
    RESPONSE=$(curl -s --request POST \
        --user ${VAR_BITBUCKET_USERNAME}:${VAR_BITBUCKET_TOKEN} \
        --url "https://api.bitbucket.org/2.0/repositories/${VAR_OWNER_AND_REPO}/pipelines_config/variables/" \
        --header 'Accept: application/json' \
        --header 'Content-Type: application/json' \
        --data "{\"type\": \"string\", \"uuid\": \"${ENVIRONMENT_UUID}\",\"key\": \"${VAR_VARIABLE_KEY}\", \"value\": \"${VAR_VARIABLE_VALUE}\", \"secured\": ${VAR_VARIABLE_SECURED} }"
    )
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
    
    curl --request PUT \
    --user ${VAR_BITBUCKET_USERNAME}:${VAR_BITBUCKET_TOKEN} \
    --url "https://api.bitbucket.org/2.0/repositories/${VAR_OWNER_AND_REPO}/pipelines_config/variables/${VAR_VARIABLE_UUID}" \
    --header 'Accept: application/json' \
    --header 'Content-Type: application/json' \
    --data "{ \"type\": \"string\",\"uuid\": \"${VAR_VARIABLE_UUID}\", \"key\": \"${VAR_VARIABLE_KEY}\", \"value\": \"${VAR_VARIABLE_VALUE}\", \"secured\": ${VAR_VARIABLE_SECURED} }"
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

    local VARIABLE=$(bitbucketGetRepositoryVariable $VAR_OWNER_AND_REPO $VAR_VARIABLE_KEY $VAR_BITBUCKET_USERNAME $VAR_BITBUCKET_TOKEN)
    if [ -z "$VARIABLE" ];then
        echo "create"
        bitbucketCreateRepositoryVariable $VAR_OWNER_AND_REPO $VAR_VARIABLE_KEY $VAR_VARIABLE_VALUE $VAR_VARIABLE_SECURED $VAR_BITBUCKET_USERNAME $VAR_BITBUCKET_TOKEN
    else
        echo "update"
        local VARIABLE_UUID=$(echo $VARIABLE | jq -r '.uuid')
        bitbucketUpdateRepositoryVariable $VAR_OWNER_AND_REPO $VARIABLE_UUID $VAR_VARIABLE_KEY $VAR_VARIABLE_VALUE $VAR_VARIABLE_SECURED $VAR_BITBUCKET_USERNAME $VAR_BITBUCKET_TOKEN
    fi
}
