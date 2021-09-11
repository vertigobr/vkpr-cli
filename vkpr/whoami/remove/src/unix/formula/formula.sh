#!/bin/sh

runFormula() {
  uninstallWhoami
}

uninstallWhoami(){
  echoColor "yellow" "Removendo Whoami..."
  $VKPR_HELM uninstall vkpr-whoami
  EXISTING_CERT=$($VKPR_KUBECTL get secret/vkpr-whoami-cert -o name --ignore-not-found | cut -d "/" -f2)
  if [[ $EXISTING_CERT = "vkpr-whoami-cert" ]]; then
    $VKPR_KUBECTL delete secret vkpr-whoami-cert
  fi
}