#!/bin/sh

runFormula() {
  echoColor "green" "Removing keycloak..."
  $VKPR_HELM uninstall --namespace $VKPR_K8S_NAMESPACE vkpr-keycloak
  $VKPR_KUBECTL delete secret --namespace $VKPR_K8S_NAMESPACE vkpr-realm-secret
}