#!/usr/bin/env bash

runFormula() {
  local VKPR_APPLICATIONSET_VALUES REPO_NAME;

  VKPR_APPLICATIONSET_VALUES=$(dirname "$0")/utils/applicationset.yaml
  REPO_NAME=$(echo "$REPO_URL" | awk -F "/" '{ print $NF }' | cut -d "." -f1)

  checkGlobalConfig "argocd" "argocd" "argocd.namespace" "ARGOCD_NAMESPACE"

  info "Creating Applicationset in Argocd"
  $VKPR_YQ eval " .metadata.name = \"$REPO_NAME-applicationset\" |
    .metadata.namespace = \"$VKPR_ENV_ARGOCD_NAMESPACE\" |
    .spec.generators[0].git.repoURL = \"$REPO_URL\" |
    .spec.template.spec.source.repoURL = \"$REPO_URL\"
  " "$VKPR_APPLICATIONSET_VALUES" | $VKPR_KUBECTL apply -f -
}
