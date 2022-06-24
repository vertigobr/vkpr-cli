#!/bin/bash

runFormula() {
  info "Removing mockserver..."

  MOCKSERVER_NAMESPACE=$($VKPR_KUBECTL get po -A -l app=mockserver -o=yaml |\
                     $VKPR_YQ e ".items[].metadata.namespace" - |\
                     head -n1)

  $VKPR_HELM uninstall mockserver -n "$MOCKSERVER_NAMESPACE" 2> /dev/null || error "VKPR mockserver not found"
}
