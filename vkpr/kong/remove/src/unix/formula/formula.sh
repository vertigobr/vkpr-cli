#!/bin/sh

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing Kong...")"

  KONG_NAMESPACE=$($VKPR_KUBECTL get po -A -l app.kubernetes.io/instance=kong,vkpr=true -o=yaml | $VKPR_YQ e ".items[].metadata.namespace" - | head -n1)
  $VKPR_HELM uninstall kong -n $KONG_NAMESPACE
  $VKPR_KUBECTL delete secret -A -l app.kubernetes.io/instance=kong,vkpr=true 2> /dev/null

  $VKPR_HELM uninstall kong-dp -n kong 2> /dev/null
  $VKPR_KUBECTL delete ns kong 2> /dev/null
}
