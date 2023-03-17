#!/usr/bin/env bash

runFormula() {
  local VKPR_LOKI_VALUES HELM_ARGS;
  formulaInputs
  validateInputs

  VKPR_LOKI_VALUES=$(dirname "$0")/utils/loki.yaml

  startInfos
  settingLoki
  [ $DRY_RUN = false ] && registerHelmRepository grafana https://grafana.github.io/helm-charts
  installApplication "loki" "grafana/loki-stack" "$VKPR_ENV_LOKI_NAMESPACE" "$VKPR_LOKI_VERSION" "$VKPR_LOKI_VALUES" "$HELM_ARGS"
  [ $DRY_RUN = false ] && existGrafana || true
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Loki Install Routine"
  boldNotice "Namespace: $VKPR_ENV_LOKI_NAMESPACE"
  bold "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "false" "false" "loki.metrics" "LOKI_METRICS"
  checkGlobalConfig "false" "false" "loki.persistence" "LOKI_PERSISTENCE"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "loki.namespace" "LOKI_NAMESPACE"

  # External app values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "GRAFANA_NAMESPACE"
}

validateInputs() {
  validateLokiMetrics "$VKPR_ENV_LOKI_METRICS"
  validateLokiPersistence "$VKPR_ENV_LOKI_PERSISTENCE"
  validateLokiNamespace "$VKPR_ENV_LOKI_NAMESPACE"

  validatePrometheusNamespace "$VKPR_ENV_GRAFANA_NAMESPACE"
}

settingLoki() {
  YQ_VALUES=".grafana.enabled = false |
    .loki.url = \"http://loki.$VKPR_ENV_LOKI_NAMESPACE:3100\"
  "

  if [[ "$VKPR_ENV_LOKI_METRICS" == true ]] && [[ $(checkPodName "$VKPR_ENV_GRAFANA_NAMESPACE" "prometheus-stack-grafana") == "true" ]]; then
    YQ_VALUES="$YQ_VALUES |
      .loki.serviceMonitor.enabled = true |
      .loki.serviceMonitor.interval = \"30s\" |
      .loki.serviceMonitor.additionalLabels.release = \"prometheus-stack\" |
      .loki.serviceMonitor.scrapeTimeout = \"30s\"
    "
  fi

  if [[ "$VKPR_ENV_LOKI_PERSISTENCE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .loki.persistence.enabled = true |
      .loki.persistence.accessModes[0] = \"ReadWriteOnce\" |
      .loki.persistence.size = \"8Gi\"
    "
  fi

  settingLokiEnvironment

  debug "YQ_CONTENT = $YQ_VALUES"
}

settingLokiEnvironment() {
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    YQ_VALUES="$YQ_VALUES"
  fi
}

existGrafana() {
  local LOGIN_GRAFANA PWD_GRAFANA

  if [[ $(checkPodName "$VKPR_ENV_GRAFANA_NAMESPACE" "prometheus-stack-grafana") == "false" ]]; then
    warn "Grafana not installed"
    return
  fi

  LOGIN_GRAFANA=$($VKPR_KUBECTL get secret --namespace "$VKPR_ENV_GRAFANA_NAMESPACE" prometheus-stack-grafana -o=jsonpath="{.data.admin-user}" | base64 -d)
  PWD_GRAFANA=$($VKPR_KUBECTL get secret --namespace "$VKPR_ENV_GRAFANA_NAMESPACE" prometheus-stack-grafana -o=jsonpath="{.data.admin-password}" | base64 -d)
  debug "server=grafana login=$LOGIN_GRAFANA password=$PWD_GRAFANA"

  createGrafanaDashboard "$(dirname "$0")/utils/dashboard.json" "$VKPR_ENV_GRAFANA_NAMESPACE"
  createGrafanaDatasource "$LOGIN_GRAFANA" "$PWD_GRAFANA"
}

createGrafanaDatasource() {
  local LOGIN_GRAFANA=$1 PWD_GRAFANA=$2

  GRAFANA_ADDRESS="grafana.${VKPR_ENV_GLOBAL_DOMAIN}"
  [[ $VKPR_ENV_GLOBAL_DOMAIN == "localhost" ]] && GRAFANA_ADDRESS="grafana.localhost:8000"

  TOKEN_API_GRAFANA=$(curl -skX POST -H "Content-Type: application/json" \
    -d '{"name": "apikeycurl'$RANDOM'","role": "Admin", "secondsToLive": 60}' \
    http://"$LOGIN_GRAFANA":"$PWD_GRAFANA"@$GRAFANA_ADDRESS/api/auth/keys | $VKPR_JQ -r '.key' -
  )
  debug "token=$TOKEN_API_GRAFANA"

  if [[ $TOKEN_API_GRAFANA == "" ]]; then
    error "Ingress is not installed to generate the api token"
    return
  fi

  EXIST_LOKI_DATASOURCE=$(curl -skX GET -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN_API_GRAFANA" \
    http://$GRAFANA_ADDRESS/api/datasources/name/loki
  )
  debug "$EXIST_LOKI_DATASOURCE"

  if [[ $EXIST_LOKI_DATASOURCE != "{\"message\":\"Data source not found\"}" ]]; then
    warn "Loki Datasource already created"
    return
  fi

  local LOKI_DATASOURCE=$($VKPR_JQ -e ".url = \"loki.$VKPR_ENV_LOKI_NAMESPACE:3100\"" "$(dirname "$0")"/utils/datasource.json)

  curl -sK -X -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN_API_GRAFANA" \
  -d "$LOKI_DATASOURCE" \
  http://$GRAFANA_ADDRESS/api/datasources > /dev/null && info "Loki Datasource Added"
}
