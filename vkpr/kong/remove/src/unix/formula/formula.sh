#!/usr/bin/env bash

runFormula() {
  HELM_FLAG="-A"
  [[ "$VKPR_ENVIRONMENT" == "okteto" ]] && HELM_FLAG=""
  KONG_DP_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG |\
                     $VKPR_JQ -r '.[] | select(.name | contains("kong-dp")) | .namespace' |\
                     head -n1)

  [ ! -z "$KONG_DP_NAMESPACE" ] && uninstallKongDP || uninstallKong
  secretRemove "kong" "$KONG_NAMESPACE"
}

uninstallKong() {
  info "Removing Kong..."

  KONG_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG |\
                     $VKPR_JQ -r '.[] | select(.name | contains("kong")) | .namespace' |\
                     head -n1)

  $VKPR_HELM uninstall --namespace "$KONG_NAMESPACE" kong 2> /dev/null || error "VKPR Kong not found"
  $VKPR_KUBECTL delete secret $HELM_FLAG --ignore-not-found=true -l app.kubernetes.io/instance=kong,app.kubernetes.io/managed-by=vkpr > /dev/null
}

uninstallKongDP() {
  info "Removing Kong DP..."

  $VKPR_HELM uninstall kong-dp -n $KONG_DP_NAMESPACE 2> /dev/null || error "VKPR Kong not found"
}
