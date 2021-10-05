#!/bin/sh

runFormula() {
  $VKPR_HELM uninstall --namespace $VKPR_K8S_NAMESPACE vkpr-prometheus-stack
}
