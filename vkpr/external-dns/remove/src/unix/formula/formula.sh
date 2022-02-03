#!/bin/sh

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing External-DNS...")"
  $VKPR_HELM uninstall -n $VKPR_K8S_NAMESPACE external-dns
}
