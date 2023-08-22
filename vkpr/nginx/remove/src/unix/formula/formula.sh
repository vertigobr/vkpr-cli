#!/usr/bin/env bash

runFormula() {
  info "Removing nginx ingress..."

  HELM_FLAG="-A"
  [[ "$VKPR_ENVIRONMENT" == "okteto" ]] && HELM_FLAG=""
  INGRESS_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG |\
                     $VKPR_JQ -r '.[] | select(.name | contains("nginx")) | .namespace' |\
                     head -n1)

  $VKPR_HELM uninstall --namespace "$INGRESS_NAMESPACE" nginx 2> /dev/null || error "VKPR nginx not found"
}
