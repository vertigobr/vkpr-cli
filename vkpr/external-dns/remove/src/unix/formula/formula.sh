#!/bin/sh

runFormula() {
<<<<<<< HEAD
  echoColor "yellow" "Removendo external-dns..."
  rm -rf $VKPR_HOME/values/external-dns
  $VKPR_HELM delete external-dns --namespace $VKPR_K8S_NAMESPACE || echoColor "red" "VKPR external-dns not found"
=======
  echoColor "green" "Removendo external-dns..."
  $VKPR_HELM uninstall -n vkpr external-dns
>>>>>>> origin/VKPR-165-revisao-formula-external-dns
}
