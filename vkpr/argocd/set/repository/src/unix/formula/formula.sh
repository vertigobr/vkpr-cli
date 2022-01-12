#!/bin/bash

runFormula() {
  local VKPR_REPO_VALUES=$(dirname "$0")/utils/repository.yaml
  local REPO_NAME=$(echo $REPO_URL | awk -F "/" '{ print $NF }' | cut -d "." -f1)
  echoColor "green" "Connecting repository in Argocd"
  $VKPR_YQ eval ' .metadata.name = "'$REPO_NAME-repo'" |
    .metadata.namespace = "argocd" |
    .stringData.url = "'$REPO_URL'" |
    .stringData.username = "'$USERNAME'" |
    .stringData.password = "'$GITLAB_TOKEN'"
  ' $VKPR_REPO_VALUES | $VKPR_KUBECTL apply -f -
}
