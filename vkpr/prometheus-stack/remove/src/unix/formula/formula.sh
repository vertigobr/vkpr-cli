#!/bin/sh

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing Prometheus-stack...")"

  PROMETHEUS_STACK_NAMESPACE=$($VKPR_KUBECTL get po -A -l app.kubernetes.io/instance=prometheus-stack,vkpr=true -o=yaml | $VKPR_YQ e ".items[].metadata.namespace" - | head -n1)
  $VKPR_HELM uninstall --namespace $PROMETHEUS_STACK_NAMESPACE prometheus-stack
  $VKPR_KUBECTL delete cm -A -l grafana_dashboard=true,vkpr=true > /dev/null
}
