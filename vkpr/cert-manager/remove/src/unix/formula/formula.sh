#!/bin/sh

runFormula() {
  echoColor "yellow" "Removing cert-manager..."
  rm -rf $VKPR_HOME/configs/cert-manager/ $VKPR_HOME/values/cert-manager/
  #$VKPR_KUBECTL delete clusterissuer letsencrypt-staging
  $VKPR_HELM uninstall cert-manager --namespace cert-manager
  #$VKPR_KUBECTL delete ns cert-manager
}
