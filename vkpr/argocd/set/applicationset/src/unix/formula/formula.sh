#!/bin/bash

runFormula() {
  local VKPR_APPLICATIONSET_VALUES=$(dirname "$0")/utils/applicationset.yaml
  local REPO_NAME=$(echo $REPO_URL | awk -F "/" '{ print $NF }' | cut -d "." -f1)
  if [[ -z $($VKPR_KUBECTL get deployment argocd-applicationset-controller -n argocd --ignore-not-found | awk 'NR>1{print $1}') ]]; then
    echoColor "red" "Dont have Addon applicationset installed in this cluster"
  else
    echoColor "green" "Creating Applicationset in Argocd"
    $VKPR_YQ eval ' .metadata.name = "'$REPO_NAME-applicationset'" |
      .metadata.namespace = "argocd" |
      .spec.generators[0].git.repoURL = "'$REPO_URL'" |
      .spec.template.spec.source.repoURL = "'$REPO_URL'"
    ' $VKPR_APPLICATIONSET_VALUES | $VKPR_KUBECTL apply -f -
  fi
}
