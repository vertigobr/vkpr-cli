#!/bin/bash

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
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Postgresql Install Routine"
  boldNotice "Password: ${PASSWORD}"
  boldNotice "HA: $VKPR_ENV_POSTGRESQL_HA"
  boldNotice "Namespace: $VKPR_ENV_POSTGRESQL_NAMESPACE"
  bold "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "$HA" "false" "postgresql.HA" "POSTGRESQL_HA"
  checkGlobalConfig "false" "false" "postgresql.metrics" "POSTGRESQL_METRICS"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "postgresql.namespace" "POSTGRESQL_NAMESPACE"
}

validateInputs() {
  validatePostgresqlPassword "$PG_PASSWORD"
  validatePostgresqlHA "$VKPR_ENV_POSTGRESQL_HA"
  validatePostgresqlMetrics "$VKPR_ENV_POSTGRESQL_METRICS"
  validatePostgresqlNamespace "$VKPR_ENV_POSTGRESQL_NAMESPACE"
}

settingPostgresql() {
  YQ_VALUES=".fullnameOverride = \"postgres-postgresql\" |
    .global.postgresql.auth.postgresPassword = \"$PG_PASSWORD\" |
    .global.postgresql.auth.database = \"postgres\" 
  "
  
  if [[ "$VKPR_ENV_POSTGRESQL_METRICS" == "true" ]]; then
    YQ_VALUES="$YQ_VALUES |
      .metrics.enabled = true |
      .metrics.serviceMonitor.enabled = true |
      .metrics.serviceMonitor.namespace = \"$VKPR_ENV_POSTGRESQL_NAMESPACE\" |
      .metrics.serviceMonitor.interval = \"1m\" |
      .metrics.serviceMonitor.scrapeTimeout = \"30m\" |
      .metrics.serviceMonitor.additionalLabels.release = \"prometheus-stack\"
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
  YQ_VALUES=".fullnameOverride = \"postgres-postgresql\" |
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
    .pgpool.adminUsername = \"postgres\" |
    .pgpool.adminPassword = \"$PG_PASSWORD\" |
    .pgpool.replicaCount = \"3\"
  "

  if [[ "$VKPR_ENV_POSTGRESQL_METRICS" == "true" ]]; then
    YQ_VALUES="$YQ_VALUES |
      .metrics.enabled = \"true\" |
      .metrics.serviceMonitor.enabled = \"true\" |
      .metrics.serviceMonitor.namespace = \"$VKPR_ENV_POSTGRESQL_NAMESPACE\" |
      .metrics.serviceMonitor.interval = \"1m\" |
      .metrics.serviceMonitor.scrapeTimeout = \"30m\" |
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