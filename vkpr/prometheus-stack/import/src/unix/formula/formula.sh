#!/bin/bash

runFormula() {
  # Global values
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "global.namespace" "GLOBAL_NAMESPACE"

  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "PROMETHEUS_STACK_NAMESPACE"
  
  info "Importing Dashboard..."
  local JSON_FILE; JSON_FILE=$(cat "$DASHBOARD_PATH")

  dashboard="$DASHBOARD_NAME-grafana" \
    $VKPR_YQ eval '(.metadata.name, .metadata.labels.app) = strenv(dashboard)' \
    "$(dirname "$0")"/utils/dashboard.yaml > "$DASHBOARD_NAME".yaml

  $VKPR_YQ eval -i ".metadata.namespace = \"$VKPR_ENV_PROMETHEUS_STACK_NAMESPACE\"" "$DASHBOARD_NAME".yaml

  $VKPR_YQ eval ".data.[\"$DASHBOARD_NAME.json\"] = (\"$JSON_FILE\" | to_json)" "$DASHBOARD_NAME".yaml |\
   $VKPR_KUBECTL apply -f -

  rm "$DASHBOARD_NAME".yaml
}
