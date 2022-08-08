#!/usr/bin/env bash

runFormula() {
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "PROMETHEUS_STACK_NAMESPACE"

  info "Importing dashboard..."
  createGrafanaDashboard "$DASHBOARD_PATH" "$VKPR_ENV_PROMETHEUS_STACK_NAMESPACE"
}
