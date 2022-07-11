#!/bin/bash

## GITHUB API REFERENCE: https://docs.github.com/en/rest/reference

## Get Repository public key
# Parameters:
# 1 - PROJECT_ID - owner/repo
# 2 - GITHUB USERNAME
# 3 - GITHUB TOKEN
githubActionsGetPublicKey(){
  local VAR_OWNER_AND_REPO=$1
  local VAR_GITHUB_USERNAME=$2
  local VAR_GITHUB_TOKEN=$3

  # https://docs.github.com/en/rest/reference/actions#get-a-repository-public-key
  {
    IFS= read -rd '' BODY
    IFS= read -rd '' HTTP_CODE
  } < <({ out=$(curl -sSL -o /dev/stderr -w "%{http_code}" -H "Accept: application/vnd.github.v3+json" -u "${VAR_GITHUB_USERNAME}":"${VAR_GITHUB_TOKEN}" "https://api.github.com/repos/\"${VAR_OWNER_AND_REPO}\"/actions/secrets/public-key"); } 2>&1; printf '\0%s' "$out" "$?")

  if [ "${HTTP_CODE}" == "200" ]; then
    ## return json compacted
    echo "$BODY" | jq -c '.'
    return 0
  else
    error "Something wrong while getting public key from github"
    exit 13
  fi

}

## Create or update a secret
## If var already exist, just update your value
# Parameters:
# 1 - PROJECT_OWNER_AND_REPO - eg: owner/project-name
# 2 - SECRET_NAME - eg: VAR_SAMPLE
# 3 - SECRET_VALUE - eg: abc
# 4 - PUBLIC_KEY - key to encrypt secret value
# 5 - GITHUB_USERNAME - github user
# 6 - GIHUB_TOKEN - github token
githubActionsCreateUpdateSecret(){
  local VAR_OWNER_AND_REPO=$1
  local VAR_SECRET_NAME=$2
  local VAR_SECRET_VALUE=$3
  local VAR_PUBLIC_KEY=$4
  local VAR_GITHUB_USERNAME=$5
  local VAR_GITHUB_TOKEN=$6

  KEY_ID=$(echo "$VAR_PUBLIC_KEY" | jq -r '.key_id')
  KEY_VALUE=$(echo "$VAR_PUBLIC_KEY" | jq -r '.key')

  SECRET=$(python3 src/lib/api/utils/github-secret-encrpty.py "${KEY_VALUE}" "${VAR_SECRET_VALUE}")

  # https://docs.github.com/en/rest/reference/actions#create-or-update-a-repository-secret
  VARIABLE_RESPONSE_CODE=$(curl -o /dev/null -w "%{http_code}" -sX PUT \
  -H "Accept: application/vnd.github.v3+json" \
  -u "${VAR_GITHUB_USERNAME}":"${VAR_GITHUB_TOKEN}" \
  https://api.github.com/repos/"${VAR_OWNER_AND_REPO}"/actions/secrets/"${VAR_SECRET_NAME}" \
  -d "{\"encrypted_value\": \"${SECRET}\", \"key_id\": \"${KEY_ID}\"}")

  case $VARIABLE_RESPONSE_CODE in
    201)
      info "Variable \"$VAR_SECRET_NAME\" created."
      ;;
    204)
      info "Variable \"$VAR_SECRET_NAME\" updated."
      ;;
    *)
      error "Something wrong while saving \"$VAR_SECRET_NAME\""
      ;;
  esac
}
