#!/usr/bin/env bash

runFormula() {
  info "Removing jaeger..."

  HELM_FLAG="-A"
  [[ "$VKPR_ENVIRONMENT" == "okteto" ]] && HELM_FLAG=""
  JAEGER_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG |\
                     $VKPR_JQ -r '.[] | select(.name | contains("jaeger")) | .namespace' |\
                     head -n1)

  $VKPR_HELM uninstall jaeger -n "$JAEGER_NAMESPACE" 2> /dev/null || error "VKPR jaeger not found"
}
