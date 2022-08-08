#!/usr/bin/env bash

runFormula() {
  info "Removing External-DNS..."

  HELM_FLAG="-A"
  [[ "$VKPR_ENVIRONMENT" == "okteto" ]] && HELM_FLAG=""
  EXTERNAL_DNS_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG |\
                     $VKPR_JQ -r '.[] | select(.name | contains("external-dns")) | .namespace' |\
                     head -n1)

  $VKPR_HELM uninstall external-dns -n "$EXTERNAL_DNS_NAMESPACE" 2> /dev/null || error "VKPR external-dns not found"
}
