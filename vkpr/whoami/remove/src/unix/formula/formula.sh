#!/bin/bash

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing whoami...")"

  WHOAMI_NAMESPACE=$($VKPR_KUBECTL get po -A -l app.kubernetes.io/instance=whoami,vkpr=true -o=yaml 2> /dev/null |\
                     $VKPR_YQ e ".items[].metadata.namespace" - |\
                     head -n1)

  $VKPR_HELM uninstall whoami -n "$WHOAMI_NAMESPACE" 2> /dev/null || echoColor "red" "VKPR whoami not found"
}