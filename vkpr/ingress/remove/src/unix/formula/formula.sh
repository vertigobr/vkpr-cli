#!/bin/sh

runFormula() {  
  echoColor "bold" "$(echoColor "green" "Removing nginx ingress...")"
  $VKPR_HELM uninstall --namespace $VKPR_K8S_NAMESPACE ingress-nginx || echoColor "red" "VKPR Ingress not found"
}
