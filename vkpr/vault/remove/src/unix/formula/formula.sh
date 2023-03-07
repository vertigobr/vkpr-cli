#!/usr/bin/env bash

runFormula() {
  info "Removing Vault..."

  HELM_FLAG="-A"
  [[ "$VKPR_ENVIRONMENT" == "okteto" ]] && HELM_FLAG=""
  VAULT_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG |\
                     $VKPR_JQ -r '.[] | select(.name | contains("vault")) | .namespace' |\
                     head -n1)

  $VKPR_HELM uninstall vault -n "$VAULT_NAMESPACE" 2> /dev/null || error "VKPR Vault not found"
  secretRemove "vault" "$VAULT_NAMESPACE"
}
