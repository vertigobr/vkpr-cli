#!/bin/sh

runFormula() {
  info "Removing Keycloak..."

  HELM_FLAG="-A"
  [ "$VKPR_ENVIRONMENT" = "okteto" ] && HELM_FLAG=""
  KEYCLOAK_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG |\
                     $VKPR_JQ -r '.[] | select(.name | contains("keycloak")) | .namespace' |\
                     head -n1)

  $VKPR_HELM uninstall keycloak -n "$KEYCLOAK_NAMESPACE" 2> /dev/null || error "VKPR Keycloak not found"
}
