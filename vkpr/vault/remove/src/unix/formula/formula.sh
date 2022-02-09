#!/bin/bash

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing Vault...")"

  VAULT_NAMESPACE=$($VKPR_KUBECTL get po -A -l app.kubernetes.io/instance=vault,vkpr=true -o=yaml | $VKPR_YQ e ".items[].metadata.namespace" - | head -n1)
  $VKPR_HELM uninstall vault -n $VAULT_NAMESPACE
  $VKPR_KUBECTL delete secret -A -l app.kubernetes.io/instance=vault,vkpr=true
}
