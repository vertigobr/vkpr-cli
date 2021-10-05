#!/bin/sh

runFormula() {
  echo "VKPR Ingress remove"
  $VKPR_HELM uninstall ingress-nginx -n vkpr
}
