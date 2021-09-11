#!/bin/sh

runFormula() {
  echoColor "green" "Removing keycloak..."
  $VKPR_HELM uninstall vkpr-keycloak
}