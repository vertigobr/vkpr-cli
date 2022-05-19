#!/bin/bash

runFormula() {
  # Global values
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "global.namespace" "GLOBAL_NAMESPACE"
  
  # App values
  checkGlobalConfig "$HA" "false" "postgresql.HA" "POSTGRESQL_HA"
  checkGlobalConfig "false" "false" "postgresql.metrics" "POSTGRESQL_METRICS"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "postgresql.namespace" "POSTGRESQL_NAMESPACE"

  validatePostgresqlPassword "$PASSWORD"

  local VKPR_POSTGRES_VALUES; VKPR_POSTGRES_VALUES=$(dirname "$0")/utils/postgres.yaml

  startInfos
  addRepoPostgres
  installPostgres
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Postgresql Install Routine")"
  echoColor "bold" "$(echoColor "blue" "Postgresql Password:") ${PASSWORD}"
  echoColor "bold" "$(echoColor "blue" "HA:") ${VKPR_ENV_POSTGRESQL_HA}"
  echo "=============================="
}

addRepoPostgres(){
  registerHelmRepository bitnami https://charts.bitnami.com/bitnami
}

installPostgres(){
  echoColor "bold" "$(echoColor "green" "Installing Postgresql...")"
  local YQ_VALUES='.fullnameOverride = "postgres-postgresql"' \
    POSTGRESQL_CHART="postgresql"
  settingPostgres

  $VKPR_YQ eval -i "$YQ_VALUES" "$VKPR_POSTGRES_VALUES"
  mergeVkprValuesHelmArgs "postgresql" "$VKPR_POSTGRES_VALUES"
  $VKPR_HELM upgrade -i --version "$VKPR_POSTGRES_VERSION" \
    --namespace "$VKPR_ENV_POSTGRESQL_NAMESPACE" --create-namespace \
    --wait -f "$VKPR_POSTGRES_VALUES" postgresql bitnami/$POSTGRESQL_CHART
}

settingPostgres() {
  if [[ "$VKPR_ENV_POSTGRESQL_HA" == "true" ]]; then
    YQ_VALUES="$YQ_VALUES |
      .postgresql.username = \"postgres\" |
      .postgresql.database = \"postgres\" |
      .postgresql.password = \"$PASSWORD\" |
      .postgresql.repmgrUsername = \"postgres\" |
      .postgresql.repmgrPassword = \"$PASSWORD\" |
      .postgresql.repmgrDatabase = \"postgres\" |
      .postgresql.postgresPassword = \"$PASSWORD\" |
      .postgresql.replicaCount = \"3\" |
      .postgresql.podLabels.vkpr = \"true\" |
      .pgpool.adminUsername = \"postgres\" |
      .pgpool.adminPassword = \"$PASSWORD\" |
      .pgpool.replicaCount = \"3\" |
      .primary = {}
    "
    POSTGRESQL_CHART="postgresql-ha"
    VKPR_POSTGRES_VERSION="8.2.5"
    else
    YQ_VALUES="$YQ_VALUES |
      .global.postgresql.postgresqlPassword = \"$PASSWORD\"
    "
  fi
  
  if [[ "$VKPR_ENV_POSTGRESQL_METRICS" == "true" ]]; then
    YQ_VALUES="$YQ_VALUES |
      .metrics.enabled = \"true\" |
      .metrics.serviceMonitor.enabled = \"true\" |
      .metrics.serviceMonitor.namespace = \"$VKPR_ENV_POSTGRESQL_NAMESPACE\" |
      .metrics.serviceMonitor.interval = \"1m\" |
      .metrics.serviceMonitor.scrapeTimeout = \"30m\"
    "
    if [[ $VKPR_ENV_POSTGRESQL_HA == "true" ]]; then
      YQ_VALUES="$YQ_VALUES | 
        .metrics.serviceMonitor.selector.release = \"prometheus-stack\"
      "
      else
      YQ_VALUES="$YQ_VALUES' | 
        .metrics.serviceMonitor.additionalLabels.release = \"prometheus-stack\"
      "
    fi
  fi
}
# $VKPR_KUBECTL patch cm --namespace vkpr tcp-services -p '{"data": {"5432": "default/postgres-postgresql:5432"}}'