#!/bin/bash

runFormula() {
  info "Removing devportal..."

  DEVPORTAL_NAMESPACE=$($VKPR_KUBECTL get po -A -l app=devportal -o=yaml |\
                     $VKPR_YQ e ".items[].metadata.namespace" - |\
                     head -n1)

  $VKPR_HELM uninstall devportal -n "$DEVPORTAL_NAMESPACE" 2> /dev/null || error "VKPR devportal not found"
}
