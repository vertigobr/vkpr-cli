#!/bin/sh

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing cert-manager...")"
  rm -rf $VKPR_HOME/configs/cert-manager/ $VKPR_HOME/values/cert-manager/
  #$VKPR_KUBECTL delete clusterissuer letsencrypt-staging
  $VKPR_HELM uninstall cert-manager -n cert-manager
  #$VKPR_KUBECTL delete ns cert-manager
}
