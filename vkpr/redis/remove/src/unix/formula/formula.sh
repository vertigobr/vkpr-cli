#!/usr/bin/env bash

runFormula() {
  info "Removing Redis..."

  HELM_FLAG="-A"
  [[ "$VKPR_ENVIRONMENT" == "okteto" ]] && HELM_FLAG=""
  REDIS_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG | $VKPR_JQ -r '.[] | select(.name | contains("redis")) | .namespace' | head -n1)

  $VKPR_HELM uninstall redis -n "$REDIS_NAMESPACE" 2> /dev/null || error "VKPR Redis not found"
}
