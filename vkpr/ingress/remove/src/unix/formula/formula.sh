#!/bin/sh

runFormula() {  
  echo "VKPR Ingress remove"
  $VKPR_HELM uninstall ingress-nginx --namespace $VKPR_K8S_NAMESPACE || echoColor "red" "VKPR Ingress not found"
}
