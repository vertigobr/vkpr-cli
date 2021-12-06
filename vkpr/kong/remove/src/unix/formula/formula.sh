#!/bin/sh

runFormula() {
  $VKPR_HELM uninstall kong-dp -n kong
  $VKPR_HELM uninstall kong -n vkpr
  $VKPR_KUBECTL delete ns kong
  $VKPR_KUBECTL delete secret kong-session-config kong-enterprise-license kong-cluster-cert -n vkpr
}
