#!/bin/bash

runFormula() {
  info "Removing whoami..."

  WHOAMI_NAMESPACE=$($VKPR_KUBECTL get po -A -l app.kubernetes.io/instance=whoami,vkpr=true -o=yaml |\
                     $VKPR_YQ e ".items[].metadata.namespace" - |\
                     head -n1)

  $VKPR_HELM uninstall whoami -n "$WHOAMI_NAMESPACE" 2> /dev/null || error "VKPR whoami not found"
}