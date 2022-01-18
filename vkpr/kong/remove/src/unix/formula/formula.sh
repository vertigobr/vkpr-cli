#!/bin/sh

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing Kong...")"
  $VKPR_HELM uninstall kong -n $VKPR_K8S_NAMESPACE
  $VKPR_KUBECTL delete secret kong-session-config kong-enterprise-license kong-cluster-cert kong-enterprise-superuser-password -n $VKPR_K8S_NAMESPACE 2> /dev/null
  $VKPR_HELM uninstall kong-dp -n kong 2> /dev/null
  $VKPR_KUBECTL delete ns kong 2> /dev/null
}
