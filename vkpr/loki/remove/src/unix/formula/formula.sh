#!/bin/sh

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing whoami...")"
  $VKPR_HELM uninstall --namespace $VKPR_K8S_NAMESPACE loki-stack
}
