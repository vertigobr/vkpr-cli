#!/bin/bash

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing ArgoCD...")"

  ARGOCD_NAMESPACE=$($VKPR_KUBECTL get po -A -l app.kubernetes.io/instance=argocd,vkpr=true -o=yaml | $VKPR_YQ e ".items[].metadata.namespace" - | head -n1)
  $VKPR_HELM uninstall argocd -n $ARGOCD_NAMESPACE 2> /dev/null

  ARGOCD_APPLICATIONSET_NAMESPACE=$($VKPR_KUBECTL get po -A -l app.kubernetes.io/instance=argocd-applicationset,vkpr=true -o=yaml | $VKPR_YQ e ".items[].metadata.namespace" - | head -n1)
  $VKPR_HELM uninstall argocd-applicationset -n $ARGOCD_APPLICATIONSET_NAMESPACE 2> /dev/null

  $VKPR_KUBECTL delete secret -A -l argocd.argoproj.io/secret-type=repository,vkpr=true > /dev/null
  $VKPR_KUBECTL delete ApplicationSet -A -l vkpr=true > /dev/null
}
