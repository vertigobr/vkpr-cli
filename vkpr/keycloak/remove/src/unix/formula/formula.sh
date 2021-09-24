#!/bin/sh

runFormula() {
  echoColor "green" "Removing keycloak..."
  $VKPR_HELM uninstall vkpr-keycloak
  $VKPR_KUBECTL delete secret vkpr-realm-secret
}