#!/bin/sh

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing Keycloak...")"
  $VKPR_HELM uninstall --namespace $VKPR_K8S_NAMESPACE keycloak
}