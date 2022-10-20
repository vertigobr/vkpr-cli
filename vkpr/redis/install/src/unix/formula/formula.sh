#!/usr/bin/env bash

runFormula() {
  local VKPR_REDIS_VALUES HELM_ARGS;
  REDIS_PASSWORD=$($VKPR_JQ -r '.credential.password' "$VKPR_CREDENTIAL"/redis)

  formulaInputs
  validateInputs

  VKPR_REDIS_VALUES=$(dirname "$0")/utils/redis.yaml

  startInfos
  settingRedis
  [ $DRY_RUN = false ] && registerHelmRepository bitnami https://charts.bitnami.com/bitnami
  installApplication "redis" "bitnami/redis" "$VKPR_ENV_REDIS_NAMESPACE" "$VKPR_REDIS_VERSION" "$VKPR_REDIS_VALUES" "$HELM_ARGS"
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Redis Install Routine"
  boldNotice "Password: ${PASSWORD}"
  boldNotice "Architecture: $VKPR_ENV_REDIS_ARCHITECTURE"
  boldNotice "Namespace: $VKPR_ENV_REDIS_NAMESPACE"
  bold "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "$ARCHITECTURE" "standalone" "redis.architecture" "REDIS_ARCHITECTURE"
  checkGlobalConfig "false" "false" "redis.metrics" "REDIS_METRICS"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "redis.namespace" "REDIS_NAMESPACE"

  # External apps values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "GRAFANA_NAMESPACE"
}


validateInputs() {
  validateRedisNamespace "$VKPR_ENV_REDIS_NAMESPACE"
  validateRedisPassword "$REDIS_PASSWORD"

  validateRedisMetrics "$VKPR_ENV_REDIS_METRICS"
}

settingRedis() {
  YQ_VALUES=".auth.password = \"$REDIS_PASSWORD\" |
    .architecture = \"$VKPR_ENV_REDIS_ARCHITECTURE\"
  "

  if [[ "$VKPR_ENV_REDIS_METRICS" == "true" ]] && [[ $(checkPodName "$VKPR_ENV_GRAFANA_NAMESPACE" "prometheus-stack-grafana") == "true" ]]; then
    YQ_VALUES="$YQ_VALUES |
      .metrics.enabled = true |
      .metrics.serviceMonitor.enabled = true |
      .metrics.serviceMonitor.namespace = \"$VKPR_ENV_REDIS_NAMESPACE\" |
      .metrics.serviceMonitor.interval = \"30s\" |
      .metrics.serviceMonitor.scrapeTimeout = \"30s\" |
      .metrics.serviceMonitor.labels.release = \"prometheus-stack\"
    "
  fi

  settingRedisEnvironment

  debug "YQ_CONTENT = $YQ_VALUES"
}

settingRedisEnvironment() {
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    YQ_VALUES="$YQ_VALUES |
      .master.persistence.size = \"2Gi\" |
      .replica.persistence.size = \"2Gi\"
    "
  fi
}
