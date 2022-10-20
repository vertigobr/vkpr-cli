#!/usr/bin/env bash

runFormula() {
  info "Removing External-secrets..."

  HELM_FLAG="-A"
  [[ "$VKPR_ENVIRONMENT" == "okteto" ]] && HELM_FLAG=""
  EXTERNAL_SECRETS_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG | $VKPR_JQ -r '.[] | select(.name | contains("external-secrets")) | .namespace' | head -n1)

  $VKPR_HELM uninstall external-secrets -n "$EXTERNAL_SECRETS_NAMESPACE" 2> /dev/null || error "VKPR External-secrets not found"
}
