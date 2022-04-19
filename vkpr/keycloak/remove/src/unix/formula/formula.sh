#!/bin/sh

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing Keycloak...")"

  KEYCLOAK_NAMESPACE=$($VKPR_KUBECTL get po -A -l app.kubernetes.io/instance=keycloak,vkpr=true -o=yaml | $VKPR_YQ e ".items[].metadata.namespace" - | head -n1)
  $VKPR_HELM uninstall keycloak -n "$KEYCLOAK_NAMESPACE"
}