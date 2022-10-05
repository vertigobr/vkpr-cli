#!/usr/bin/env bash

runFormula() {
  boldInfo "Removing ArgoCD..."

  HELM_FLAG="-A"
  [[ "$VKPR_ENVIRONMENT" == "okteto" ]] && HELM_FLAG=""
  ARGOCD_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG |\
                     $VKPR_JQ -r '.[] | select(.name | contains("argocd")) | .namespace' |\
                     head -n1)

  $VKPR_KUBECTL delete secret $HELM_FLAG --ignore-not-found=true -l argocd.argoproj.io/secret-type=repository,app.kubernetes.io/managed-by=vkpr > /dev/null
  $VKPR_HELM uninstall argo-workflows -n "argo-workflows" 2> /dev/null
  $VKPR_HELM uninstall argo-events -n "argo-events" 2> /dev/null
  $VKPR_HELM uninstall argo-rollouts -n "$ARGOCD_NAMESPACE" 2> /dev/null

  $VKPR_HELM uninstall argocd -n "$ARGOCD_NAMESPACE" 2> /dev/null || error "VKPR Argocd not found"
}
