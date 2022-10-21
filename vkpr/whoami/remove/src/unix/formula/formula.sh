#!/usr/bin/env bash

runFormula() {
  info "Removing whoami..."

  HELM_FLAG="-A"
  [[ "$VKPR_ENVIRONMENT" == "okteto" ]] && HELM_FLAG=""
  WHOAMI_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG |\
                     $VKPR_JQ -r '.[] | select(.name | contains("whoami")) | .namespace' |\
                     head -n1)

  $VKPR_HELM uninstall whoami -n "$WHOAMI_NAMESPACE" 2> /dev/null || error "VKPR whoami not found"
  $VKPR_KUBECTL delete all -n "$WHOAMI_NAMESPACE" -l="app.kubernetes.io/managed-by=vkpr" --ignore-not-found
}
