#!/bin/sh

runFormula() {  
  echo "VKPR Ingress remove"
<<<<<<< HEAD
  $VKPR_HELM uninstall ingress-nginx -n vkpr
=======
  $VKPR_HELM uninstall --namespace $VKPR_K8S_NAMESPACE ingress-nginx || echoColor "red" "VKPR Ingress not found"
>>>>>>> origin/stage
}
