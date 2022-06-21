#!/bin/bash

runFormula() {
  bold "$(info "Removing ArgoCD...")"

  $VKPR_KUBECTL get crd | grep -q applicationsets.argoproj.io && uninstallApplicationset
  uninstallResources
  uninstallArgo
}

uninstallArgo() {
  ARGOCD_NAMESPACE=$($VKPR_KUBECTL get po -A -l app.kubernetes.io/instance=argocd,vkpr=true -o=yaml |\
                     $VKPR_YQ e ".items[].metadata.namespace" - |\
                     head -n1)

  $VKPR_HELM uninstall argocd -n "$ARGOCD_NAMESPACE" 2> /dev/null || error "VKPR Argocd not found"
}

uninstallApplicationset() {
  ARGOCD_APPLICATIONSET_NAMESPACE=$($VKPR_KUBECTL get po -A -l app.kubernetes.io/instance=argocd-applicationset,vkpr=true -o=yaml |\
                                    $VKPR_YQ e ".items[].metadata.namespace" - |\
                                    head -n1)

  $VKPR_HELM uninstall argocd-applicationset -n "$ARGOCD_APPLICATIONSET_NAMESPACE" 2> /dev/null || error "VKPR Argocd Applicationset not found"
  $VKPR_KUBECTL delete ApplicationSet -A --ignore-not-found=true -l vkpr=true > /dev/null
}

uninstallResources() {
  $VKPR_KUBECTL delete secret -A --ignore-not-found=true -l argocd.argoproj.io/secret-type=repository,vkpr=true > /dev/null
}