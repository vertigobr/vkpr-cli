#!/bin/sh

runFormula() {
  echoColor "green" "Removing keycloak..."
  $VKPR_HELM uninstall --namespace $VKPR_K8S_NAMESPACE keycloak
  $VKPR_KUBECTL delete secret --namespace $VKPR_K8S_NAMESPACE realm-secret
}