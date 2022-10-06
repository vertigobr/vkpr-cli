#!/usr/bin/env bash

runFormula() {
  info "Removing Nexus..."

  HELM_FLAG="-A"
  [[ "$VKPR_ENVIRONMENT" == "okteto" ]] && HELM_FLAG=""
  NEXUS_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG | $VKPR_JQ -r '.[] | select(.name | contains("nexus")) | .namespace' | head -n1)

  $VKPR_HELM uninstall nexus -n "$NEXUS_NAMESPACE" 2> /dev/null || error "VKPR Nexus not found"
}
