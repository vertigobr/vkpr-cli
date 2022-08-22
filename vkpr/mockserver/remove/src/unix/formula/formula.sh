#!/usr/bin/env bash

runFormula() {
  info "Removing mockserver..."

  HELM_FLAG="-A"
  [[ "$VKPR_ENVIRONMENT" == "okteto" ]] && HELM_FLAG=""
  MOCKSERVER_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG |\
                     $VKPR_JQ -r '.[] | select(.name | contains("mockserver")) | .namespace' |\
                     head -n1)

  $VKPR_HELM uninstall mockserver -n "$MOCKSERVER_NAMESPACE" 2> /dev/null || error "VKPR mockserver not found"
}
