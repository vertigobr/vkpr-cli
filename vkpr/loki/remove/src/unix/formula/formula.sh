#!/usr/bin/env bash

runFormula() {
  info "Removing Loki..."

  HELM_FLAG="-A"
  [[ "$VKPR_ENVIRONMENT" == "okteto" ]] && HELM_FLAG=""
  LOKI_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG |\
                     $VKPR_JQ -r '.[] | select(.name | contains("loki")) | .namespace' |\
                     head -n1)

  $VKPR_HELM uninstall --namespace "$LOKI_NAMESPACE" loki-stack 2> /dev/null || error "VKPR Loki not found"
}
