#!/bin/sh

runFormula() {
  echoColor "green" "Removendo external-dns..."
  $VKPR_HELM uninstall --namespace $VKPR_K8S_NAMESPACE external-dns || echoColor "red" "VKPR external-dns not found"
}
