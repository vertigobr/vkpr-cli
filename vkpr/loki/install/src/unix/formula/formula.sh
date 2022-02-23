#!/bin/bash

runFormula() {
  checkGlobalConfig "false" "false" "loki.metrics" "LOKI_METRICS"
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "loki.namespace" "LOKI_NAMESPACE"

  # External app values
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "prometheus-stack.namespace" "GRAFANA_NAMESPACE"

  local VKPR_LOKI_VALUES; VKPR_LOKI_VALUES=$(dirname "$0")/utils/loki.yaml

  startInfos
  addRepLoki
  installLoki
  existGrafana
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Loki Install Routine")"
  echo "=============================="
}

addRepLoki(){
  registerHelmRepository grafana https://grafana.github.io/helm-charts
}

installLoki(){
  echoColor "bold" "$(echoColor "green" "Installing Loki...")"
  local YQ_VALUES=".grafana.enabled = false"
  settingLoki

  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_LOKI_VALUES" \
  | $VKPR_HELM upgrade -i --version "$VKPR_LOKI_VERSION" \
    --namespace "$VKPR_ENV_LOKI_NAMESPACE" --create-namespace \
    --wait -f - loki-stack grafana/loki-stack
}

settingLoki() {
  if [[ "$VKPR_ENV_LOKI_METRICS" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .loki.serviceMonitor.enabled = true |
      .loki.serviceMonitor.interval = \"30s\" |
      .loki.serviceMonitor.additionalLabels.release = \"prometheus-stack\" |
      .loki.serviceMonitor.scrapeTimeout = \"30s\"
    "
  fi

  mergeVkprValuesHelmArgs "loki" "$VKPR_LOKI_VALUES"
}

existGrafana() {
  if [[ $(checkPodName "$VKPR_ENV_GRAFANA_NAMESPACE" "prometheus-stack-grafana") == "true" ]]; then
    local LOGINGRAFANA TOKEN_API_GRAFANA
    LOGINGRAFANA="$($VKPR_KUBECTL get secret --namespace "$VKPR_ENV_GRAFANA_NAMESPACE" prometheus-stack-grafana -o yaml |\
                    $VKPR_YQ eval '.data.admin-user' - | base64 -d):$($VKPR_KUBECTL get secret --namespace "$VKPR_ENV_GRAFANA_NAMESPACE" prometheus-stack-grafana -o yaml | $VKPR_YQ eval '.data.admin-password' - | base64 -d)"

    TOKEN_API_GRAFANA=$(curl -skX POST \
      -H "Host: grafana.${VKPR_ENV_DOMAIN}" -H "Content-Type: application/json" \
      -d '{"name": "apikeycurl","role": "Admin"}'   
      http://"$LOGINGRAFANA"@127.0.0.1:8000/api/auth/keys | $VKPR_JQ --raw-output '.key'
    )

    if [[ $TOKEN_API_GRAFANA == "" ]]; then
      echoColor "red" "Api Token can only be request once or ingress is not installed."
    fi

    curl -sK -X \
    -H "Host: grafana.$VKPR_ENV_DOMAIN" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN_API_GRAFANA" \
    -d '{
          "name":"loki",
          "type":"loki",
          "url":"loki-stack.'"$VKPR_ENV_LOKI_NAMESPACE"'.svc.cluster.local:3100",
          "access":"proxy",
          "basicAuth":false,
          "editable": true
        }' http://127.0.0.1:8000/api/datasources
  fi
}