#!/bin/bash

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing ArgoCD...")"
  $VKPR_HELM uninstall -n argocd argocd
  $VKPR_KUBECTL delete secret -n argocd -l argocd.argoproj.io/secret-type=repository 2> /dev/null
  $VKPR_KUBECTL delete ApplicationSet -n argocd -l argo-setup=vkpr 2> /dev/null
  $VKPR_KUBECTL delete -n argocd \
      -f https://raw.githubusercontent.com/argoproj-labs/applicationset/$VKPR_ARGOCD_ADDON_APPLICATIONSET_VERSION/manifests/install.yaml 2> /dev/null
}
