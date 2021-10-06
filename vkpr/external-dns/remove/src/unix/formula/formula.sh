#!/bin/sh

runFormula() {
  echoColor "green" "Removendo external-dns..."
  $VKPR_HELM uninstall -n vkpr external-dns
}
