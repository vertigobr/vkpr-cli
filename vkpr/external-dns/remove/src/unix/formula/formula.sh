#!/bin/sh

runFormula() {
  echoColor "yellow" "Removendo external-dns..."
  $VKPR_HELM uninstall vkpr-external-dns
}
