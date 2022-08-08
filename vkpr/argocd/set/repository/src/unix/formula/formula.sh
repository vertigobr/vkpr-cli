#!/usr/bin/env bash

runFormula() {
  local VKPR_REPO_VALUES REPO_NAME;

  VKPR_REPO_VALUES="$(dirname "$0")"/utils/repository.yaml
  REPO_NAME=$(echo "$REPO_URL" | awk -F "/" '{ print $NF }' | cut -d "." -f1)

  checkGlobalConfig "argocd" "argocd" "argocd.namespace" "ARGOCD_NAMESPACE"

  validateGitlabUsername "$GITLAB_USERNAME"
  validateGitlabToken "$GITLAB_TOKEN"

  info "Connecting repository in Argocd"
  $VKPR_YQ eval ".metadata.name = \"${REPO_NAME}-repo\" |
    .metadata.namespace = \"$VKPR_ENV_ARGOCD_NAMESPACE\" |
    .stringData.url = \"$REPO_URL\" |
    .stringData.username = \"$GITLAB_USERNAME\" |
    .stringData.password = \"$GITLAB_TOKEN\"
  " "$VKPR_REPO_VALUES" | $VKPR_KUBECTL apply -f -
}
