#!/usr/bin/env bash

runFormula() {
  bold "$(info "Removing Consul...")"

  HELM_FLAG="-A"
  [[ "$VKPR_ENVIRONMENT" == "okteto" ]] && HELM_FLAG=""
  CONSUL_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG |\
                     $VKPR_JQ -r '.[] | select(.name | contains("consul")) | .namespace' |\
                     head -n1)

  $VKPR_HELM uninstall consul -n "$CONSUL_NAMESPACE" 2> /dev/null || error "VKPR consul not found"
}
