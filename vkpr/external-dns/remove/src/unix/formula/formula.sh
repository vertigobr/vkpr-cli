#!/bin/sh

runFormula() {
  echoColor "yellow" "Removendo external-dns..."
  rm -rf $VKPR_HOME/values/external-dns
  $VKPR_HELM delete external-dns --namespace $VKPR_K8S_NAMESPACE || echoColor "red" "VKPR external-dns not found"
}
