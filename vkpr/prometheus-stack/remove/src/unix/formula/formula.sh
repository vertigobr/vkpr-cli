#!/bin/bash

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing Prometheus-stack...")"

  PROMETHEUS_STACK_NAMESPACE=$($VKPR_KUBECTL get po -A -l app.kubernetes.io/instance=prometheus-stack,vkpr=true -o=yaml |\
                               $VKPR_YQ e ".items[].metadata.namespace" - |\
                               head -n1)

  $VKPR_KUBECTL delete cm -A --ignore-not-found=true -l grafana_dashboard=true,vkpr=true > /dev/null
  $VKPR_HELM uninstall -n "$PROMETHEUS_STACK_NAMESPACE" prometheus-stack 2> /dev/null || echoColor "red" "VKPR Prometheus-stack not found"
} 
