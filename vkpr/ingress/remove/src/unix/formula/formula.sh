#!/bin/sh

runFormula() {  
  echo "VKPR Ingress remove"
  $VKPR_HELM uninstall --namespace $VKPR_K8S_NAMESPACE ingress-nginx || echoColor "red" "VKPR Ingress not found"
}
