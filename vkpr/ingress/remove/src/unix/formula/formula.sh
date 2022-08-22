#!/usr/bin/env bash

runFormula() {
  info "Removing nginx ingress..."

  HELM_FLAG="-A"
  [[ "$VKPR_ENVIRONMENT" == "okteto" ]] && HELM_FLAG=""
  INGRESS_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG |\
                     $VKPR_JQ -r '.[] | select(.name | contains("ingress-nginx")) | .namespace' |\
                     head -n1)

  $VKPR_HELM uninstall --namespace "$INGRESS_NAMESPACE" ingress-nginx 2> /dev/null || error "VKPR ingress-nginx not found"
}
