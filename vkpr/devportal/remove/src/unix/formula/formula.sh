#!/usr/bin/env bash

runFormula() {
  info "Removing devportal..."

  HELM_FLAG="-A"
  [[ "$VKPR_ENVIRONMENT" == "okteto" ]] && HELM_FLAG=""
  DEVPORTAL_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG |\
                     $VKPR_JQ -r '.[] | select(.name | contains("devportal")) | .namespace' |\
                     head -n1)


  $VKPR_HELM uninstall devportal -n "$DEVPORTAL_NAMESPACE" 2> /dev/null || error "VKPR devportal not found"
  secretRemove "devportal" "$DEVPORTAL_NAMESPACE"
}
