#!/bin/bash

runFormula() {
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "PROMETHEUS_STACK_NAMESPACE"

  info "Importing Dashboard..."
  dashboard="$DASHBOARD_NAME-grafana" \
  $VKPR_YQ eval "(.metadata.name, .metadata.labels.app) = strenv(dashboard) |
    .data.[\"$DASHBOARD_NAME.json\"] = ($(cat $DASHBOARD_PATH) | to_json)
  " "$(dirname "$0")"/utils/dashboard.yaml | $VKPR_KUBECTL apply -n $VKPR_ENV_PROMETHEUS_STACK_NAMESPACE -f -
}