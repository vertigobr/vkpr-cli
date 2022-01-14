#!/bin/sh

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing External-DNS...")"
  $VKPR_HELM uninstall -n vkpr external-dns
}
