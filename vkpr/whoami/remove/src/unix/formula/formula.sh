#!/bin/sh

runFormula() {
  uninstallWhoami
}

uninstallWhoami(){
  echoColor "green" "Removendo Whoami..."
  $VKPR_HELM uninstall whoami -n vkpr
  EXISTING_CERT=$($VKPR_KUBECTL get secret/whoami-cert -o name --ignore-not-found | cut -d "/" -f2)
  if [[ $EXISTING_CERT = "whoami-cert" ]]; then
    $VKPR_KUBECTL delete secret whoami-cert -n vkpr 
  fi
}