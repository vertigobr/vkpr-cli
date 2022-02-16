#!/bin/bash

runFormula() {
  echoColor "bold" "$(echoColor "green" "Importing Dashboard...")"
  local JSON_FILE=$(cat $DASHBOARD_PATH)

  checkGlobalConfig $VKPR_K8S_NAMESPACE "vkpr" "prometheus-stack.namespace" "NAMESPACE"

  dashboard="$DASHBOARD_NAME-grafana" $VKPR_YQ eval '(.metadata.name, .metadata.labels.app) = strenv(dashboard)' $(dirname "$0")/utils/dashboard.yaml > $DASHBOARD_NAME.yaml
  $VKPR_YQ eval -i '.metadata.namespace = "'$VKPR_ENV_NAMESPACE'"' $DASHBOARD_NAME.yaml
  $VKPR_YQ eval '.data.["'$DASHBOARD_NAME.json'"] = ('"$JSON_FILE"' | to_json)' $DASHBOARD_NAME.yaml \
  | $VKPR_KUBECTL apply -f -
  rm $DASHBOARD_NAME.yaml
}
