#!/bin/bash

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing Loki...")"
  
  LOKI_NAMESPACE=$($VKPR_KUBECTL get po -A -l release=loki-stack,vkpr=true -o=yaml |\
                   $VKPR_YQ e ".items[].metadata.namespace" - |\
                   head -n1)

  $VKPR_HELM uninstall --namespace "$LOKI_NAMESPACE" loki-stack 2> /dev/null || echoColor "red" "VKPR Loki not found"
}
