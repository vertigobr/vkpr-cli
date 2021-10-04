#!/bin/sh

runFormula() {
  echoColor "green" "Removing Loki..."
  $VKPR_HELM uninstall --namespace $VKPR_K8S_NAMESPACE vkpr-loki-stack
}
