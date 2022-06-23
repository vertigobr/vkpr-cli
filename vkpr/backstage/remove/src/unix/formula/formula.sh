#!/bin/bash

runFormula() {
  info "Removing backstage..."

  BACKSTAGE_NAMESPACE=$($VKPR_KUBECTL get po -A -l app.kubernetes.io/instance=backstage -o=yaml |\
                     $VKPR_YQ e ".items[].metadata.namespace" - |\
                     head -n1)

  $VKPR_HELM uninstall backstage -n "$BACKSTAGE_NAMESPACE" 2> /dev/null || error "VKPR backstage not found"
}
