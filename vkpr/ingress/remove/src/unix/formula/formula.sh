#!/bin/bash

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing nginx ingress...")"

  INGRESS_NAMESPACE=$($VKPR_KUBECTL get po -A -l app.kubernetes.io/instance=ingress-nginx,vkpr=true -o=yaml |\
                      $VKPR_YQ e ".items[].metadata.namespace" - |\
                      head -n1)

  $VKPR_HELM uninstall --namespace "$INGRESS_NAMESPACE" ingress-nginx 2> /dev/null || echoColor "red" "VKPR ingress-nginx not found"
}
