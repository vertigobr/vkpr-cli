#!/usr/bin/env bash

runFormula() {
  info "Removing Tempo..."

  HELM_FLAG="-A"
  [[ "$VKPR_ENVIRONMENT" == "okteto" ]] && HELM_FLAG=""
  TEMPO_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG | $VKPR_JQ -r '.[] | select(.name | contains("tempo")) | .namespace' | head -n1)

  $VKPR_HELM uninstall tempo -n "$TEMPO_NAMESPACE" 2> /dev/null || error "VKPR Tempo not found"
}
