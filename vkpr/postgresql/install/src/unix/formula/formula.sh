#!/usr/bin/env bash
source "$(dirname "$0")"/unix/formula/commands-operators.sh

runFormula() {
  local VKPR_POSTGRESQL_VALUES PG_PASSWORD HELM_ARGS;
  PG_PASSWORD=$($VKPR_JQ -r '.credential.password' "$VKPR_CREDENTIAL"/postgres)

  formulaInputs
  validateInputs

  VKPR_POSTGRESQL_VALUES=$(dirname "$0")/utils/postgres.yaml

  startInfos
  [ $DRY_RUN = false ] && registerHelmRepository bitnami https://charts.bitnami.com/bitnami
  if [[ "$VKPR_ENV_POSTGRESQL_HA" == "false" ]]; then
    settingPostgresql
    installApplication "postgresql" "bitnami/postgresql" "$VKPR_ENV_POSTGRESQL_NAMESPACE" "$VKPR_POSTGRESQL_VERSION" "$VKPR_POSTGRESQL_VALUES" "$HELM_ARGS"
  else
    settingPostgresqlHA
    installApplication "postgresql" "bitnami/postgresql-ha" "$VKPR_ENV_POSTGRESQL_NAMESPACE" "$VKPR_POSTGRESQL_HA_VERSION" "$VKPR_POSTGRESQL_VALUES" "$HELM_ARGS"
  fi
  [ $DRY_RUN = false ] && checkComands
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Postgresql Install Routine"
  boldNotice "Password: ${PASSWORD}"
  boldNotice "HA: $VKPR_ENV_POSTGRESQL_HA"
  [[ "$VKPR_ENVIRONMENT" != "okteto" ]] && boldNotice "Namespace: $VKPR_ENV_POSTGRESQL_NAMESPACE"
  bold "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "$HA" "false" "postgresql.HA" "POSTGRESQL_HA"
  checkGlobalConfig "false" "false" "postgresql.metrics" "POSTGRESQL_METRICS"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "postgresql.namespace" "POSTGRESQL_NAMESPACE"
  checkGlobalConfig "8Gi" "8Gi" "postgresql.persistanceSize" "POSTGRESQL_VOLUME_SIZE"

  # External apps values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "GRAFANA_NAMESPACE"
}

validateInputs() {
  validatePostgresqlPassword "$PG_PASSWORD"
  validatePostgresqlHA "$VKPR_ENV_POSTGRESQL_HA"
  validatePostgresqlMetrics "$VKPR_ENV_POSTGRESQL_METRICS"
  validatePostgresqlNamespace "$VKPR_ENV_POSTGRESQL_NAMESPACE"

  validatePostgresqlVolumeSize "$VKPR_ENV_POSTGRESQL_VOLUME_SIZE"
}

settingPostgresql() {
  YQ_VALUES=".fullnameOverride = \"postgres-postgresql\" |
    .global.postgresql.auth.postgresPassword = \"$PG_PASSWORD\" |
    .global.postgresql.auth.database = \"postgres\" |
    .primary.persistence.size = \"$VKPR_ENV_POSTGRESQL_VOLUME_SIZE\"
  "

  if [[ "$VKPR_ENV_POSTGRESQL_METRICS" == "true" ]] && [[ $(checkPodName "$VKPR_ENV_GRAFANA_NAMESPACE" "prometheus-stack-grafana") == "true" ]]; then
    createGrafanaDashboard "$(dirname "$0")/utils/dashboard.json" "$VKPR_ENV_GRAFANA_NAMESPACE"
    YQ_VALUES="$YQ_VALUES |
      .metrics.enabled = true |
      .metrics.serviceMonitor.enabled = true |
      .metrics.serviceMonitor.namespace = \"$VKPR_ENV_POSTGRESQL_NAMESPACE\" |
      .metrics.serviceMonitor.interval = \"1m\" |
      .metrics.serviceMonitor.scrapeTimeout = \"1m\" |
      .metrics.serviceMonitor.labels.release = \"prometheus-stack\"
    "
  fi

  settingPostgresqlProvider

  debug "YQ_CONTENT = $YQ_VALUES"
}

settingPostgresqlProvider(){
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    YQ_VALUES="$YQ_VALUES |
      .primary.persistence.size = \"2Gi\"
    "
  fi

}

settingPostgresqlHA() {
  YQ_VALUES=".fullnameOverride = \"postgres\" |
    .commonLabels.[\"app.kubernetes.io/managed-by\"] = \"vkpr\" |
    .postgresql.username = \"postgres\" |
    .postgresql.database = \"postgres\" |
    .postgresql.password = \"$PG_PASSWORD\" |
    .postgresql.repmgrUsername = \"postgres\" |
    .postgresql.repmgrPassword = \"$PG_PASSWORD\" |
    .postgresql.repmgrDatabase = \"postgres\" |
    .postgresql.postgresPassword = \"$PG_PASSWORD\" |
    .postgresql.replicaCount = \"3\" |
    .postgresql.podLabels.vkpr = \"true\" |
    .postgresql.topologySpreadConstraints[0].maxSkew = 1 |
    .postgresql.topologySpreadConstraints[0].topologyKey = \"kubernetes.io/hostname\" |
    .postgresql.topologySpreadConstraints[0].whenUnsatisfiable = \"ScheduleAnyway\" |
    .postgresql.topologySpreadConstraints[0].labelSelector.matchLabels.[\"app.kubernetes.io/managed-by\"] = \"vkpr\" |
    .postgresql.pdb.create = \"true\" |
    .postgresql.pdb.minAvailable = \"1\" |
    .pgpool.adminUsername = \"postgres\" |
    .pgpool.adminPassword = \"$PG_PASSWORD\" |
    .pgpool.replicaCount = \"3\" |
    .pgpool.topologySpreadConstraints[0].maxSkew = 1 |
    .pgpool.topologySpreadConstraints[0].topologyKey = \"kubernetes.io/hostname\" |
    .pgpool.topologySpreadConstraints[0].whenUnsatisfiable = \"ScheduleAnyway\" |
    .pgpool.topologySpreadConstraints[0].labelSelector.matchLabels.[\"app.kubernetes.io/managed-by\"] = \"vkpr\" |
    .pgpool.pdb.create = \"true\" |
    .pgpool.pdb.minAvailable = \"1\" |
    .persistence.size = \"$VKPR_ENV_POSTGRESQL_VOLUME_SIZE\"
  "

  if [[ "$VKPR_ENV_POSTGRESQL_METRICS" == "true" ]] && [[ $(checkPodName "$VKPR_ENV_GRAFANA_NAMESPACE" "prometheus-stack-grafana") == "true" ]]; then
    createGrafanaDashboard "$(dirname "$0")/utils/dashboard.json" "$VKPR_ENV_GRAFANA_NAMESPACE"
    YQ_VALUES="$YQ_VALUES |
      .metrics.enabled = \"true\" |
      .metrics.serviceMonitor.enabled = \"true\" |
      .metrics.serviceMonitor.namespace = \"$VKPR_ENV_POSTGRESQL_NAMESPACE\" |
      .metrics.serviceMonitor.interval = \"1m\" |
      .metrics.serviceMonitor.scrapeTimeout = \"1m\"
      .metrics.serviceMonitor.selector.release = \"prometheus-stack\"
    "
  fi

  settingPostgresqlHAProvider

  debug "YQ_CONTENT = $YQ_VALUES"
}

settingPostgresqlHAProvider(){
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    YQ_VALUES="$YQ_VALUES |
      .persistence.size = \"2Gi\"
    "
  fi
}

checkComands (){
  COMANDS_EXISTS=$($VKPR_YQ eval ".postgresql | has(\"commands\")" "$VKPR_FILE" 2> /dev/null)
  debug "$COMANDS_EXISTS"
  if [ "$COMANDS_EXISTS" == true ]; then
    bold "=============================="
    boldInfo "Checking additional postgresql commands..."
    if [ $($VKPR_YQ eval ".postgresql.commands | has(\"createDb\")" "$VKPR_FILE") == true ]; then
      createDbPostgresql 
    fi
  fi
}