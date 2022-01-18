#!/bin/sh

runFormula() {
  uninstallWhoami
}

uninstallWhoami(){
  echoColor "bold" "$(echoColor "green" "Removing whoami...")"
  $VKPR_HELM uninstall whoami -n $VKPR_K8S_NAMESPACE
  local EXISTING_CERT=$($VKPR_KUBECTL get secret/whoami-cert -n $VKPR_K8S_NAMESPACE -o name --ignore-not-found | cut -d "/" -f2)
  if [[ $EXISTING_CERT = "whoami-cert" ]]; then
    $VKPR_KUBECTL delete secret -n $VKPR_K8S_NAMESPACE whoami-cert
  fi
}