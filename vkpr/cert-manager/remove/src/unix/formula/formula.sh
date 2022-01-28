#!/bin/sh

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing cert-manager...")"
  #$VKPR_KUBECTL delete clusterissuer certmanager-issuer -n cert-manager
  $VKPR_HELM uninstall cert-manager -n cert-manager
  $VKPR_KUBECTL delete ns cert-manager
}
