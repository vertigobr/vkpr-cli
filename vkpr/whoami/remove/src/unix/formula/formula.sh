#!/bin/sh

runFormula() {
  uninstallWhoami
}

uninstallWhoami(){
  echoColor "yellow" "Removendo Whoami..."
  $VKPR_HELM uninstall --namespace $VKPR_K8S_NAMESPACE vkpr-whoami
  EXISTING_CERT=$($VKPR_KUBECTL get secret/vkpr-whoami-cert --namespace $VKPR_K8S_NAMESPACE -o name --ignore-not-found | cut -d "/" -f2)
  if [[ $EXISTING_CERT = "vkpr-whoami-cert" ]]; then
    $VKPR_KUBECTL delete secret --namespace $VKPR_K8S_NAMESPACE vkpr-whoami-cert
  fi
}