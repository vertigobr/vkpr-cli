#!/bin/sh

runFormula() {
  uninstallWhoami
}

uninstallWhoami(){
  echoColor "green" "Removendo Whoami..."
  $VKPR_HELM uninstall whoami --namespace $VKPR_K8S_NAMESPACE
  EXISTING_CERT=$($VKPR_KUBECTL get secret/whoami-cert --namespace $VKPR_K8S_NAMESPACE -o name --ignore-not-found | cut -d "/" -f2)
  if [[ $EXISTING_CERT = "whoami-cert" ]]; then
    $VKPR_KUBECTL delete secret whoami-cert --namespace $VKPR_K8S_NAMESPACE
  fi
}