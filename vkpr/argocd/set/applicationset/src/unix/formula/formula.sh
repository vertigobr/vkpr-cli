#!/bin/bash

runFormula() {
  checkGlobalConfig "argocd" "argocd" "argocd.namespace" "ARGOCD_NAMESPACE"

  local VKPR_APPLICATIONSET_VALUES REPO_NAME; 
  VKPR_APPLICATIONSET_VALUES=$(dirname "$0")/utils/applicationset.yaml
  REPO_NAME=$(echo "$REPO_URL" | awk -F "/" '{ print $NF }' | cut -d "." -f1)

  if [[ -z $($VKPR_KUBECTL get deployment argocd-application-controller -n "$VKPR_ENV_ARGOCD_NAMESPACE" --ignore-not-found | awk 'NR>1{print $1}') ]]; then
    echoColor "red" "Dont have Addon applicationset installed in this cluster"
  else
    echoColor "green" "Creating Applicationset in Argocd"
    $VKPR_YQ eval " .metadata.name = \"$REPO_NAME-applicationset\" |
      .metadata.namespace = \"$VKPR_ENV_ARGOCD_NAMESPACE\" |
      .spec.generators[0].git.repoURL = \"$REPO_URL\" |
      .spec.template.spec.source.repoURL = \"$REPO_URL\"
    " "$VKPR_APPLICATIONSET_VALUES" | $VKPR_KUBECTL apply -f -
  fi
}
