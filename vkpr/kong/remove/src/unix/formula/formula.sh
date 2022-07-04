#!/bin/bash

runFormula() {
  $VKPR_KUBECTL get namespace | grep -q kong && uninstallKongDP
  uninstallKong
}

uninstallKong() {
  info "Removing Kong..."

  KONG_NAMESPACE=$($VKPR_KUBECTL get po -A -l app.kubernetes.io/instance=kong,vkpr=true -o=yaml |\
                   $VKPR_YQ e ".items[].metadata.namespace" - |\
                   head -n1)

  $VKPR_HELM uninstall --namespace "$KONG_NAMESPACE" kong 2> /dev/null || error "VKPR Kong not found"
  $VKPR_KUBECTL delete secret -A --ignore-not-found=true -l app.kubernetes.io/instance=kong,app.kubernetes.io/managed-by=vkpr > /dev/null
}

uninstallKongDP() {
  info "Removing Kong DP..."

  $VKPR_HELM uninstall kong-dp -n kong 2> /dev/null || error "VKPR Kong not found"
  $VKPR_KUBECTL delete ns kong 2> /dev/null || error "VKPR Kong not found"
}