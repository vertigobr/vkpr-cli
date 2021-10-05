#!/bin/sh

runFormula() {  
  echo "VKPR Ingress remove"
  $VKPR_HELM uninstall vkpr-ingress --namespace $VKPR_K8S_NAMESPACE || echoColor "red" "VKPR Ingress not found"
}
