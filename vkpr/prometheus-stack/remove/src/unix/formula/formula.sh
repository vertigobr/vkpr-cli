#!/bin/sh

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing Prometheus-stack...")"
  $VKPR_HELM uninstall --namespace $VKPR_K8S_NAMESPACE prometheus-stack
  $VKPR_KUBECTL delete cm -n $VKPR_K8S_NAMESPACE -l grafana_dashboard=true > /dev/null
}
