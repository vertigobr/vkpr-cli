#!/usr/bin/env bash

runFormula() {
  info "Removing Prometheus-stack..."

  HELM_FLAG="-A"
  [[ "$VKPR_ENVIRONMENT" == "okteto" ]] && HELM_FLAG=""
  PROMETHEUS_STACK_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG |\
                     $VKPR_JQ -r '.[] | select(.name | contains("prometheus-stack")) | .namespace' |\
                     head -n1)

  $VKPR_KUBECTL delete cm $HELM_FLAG --ignore-not-found=true -l grafana_dashboard=1,app.kubernetes.io/managed-by=vkpr > /dev/null
  $VKPR_HELM uninstall -n "$PROMETHEUS_STACK_NAMESPACE" prometheus-stack 2> /dev/null || error "VKPR Prometheus-stack not found"
  secretRemove "prometheus" "$PROMETHEUS_STACK_NAMESPACE"
  secretRemove "alertmanager" "$PROMETHEUS_STACK_NAMESPACE"
  secretRemove "grafana" "$PROMETHEUS_STACK_NAMESPACE"
}
