#!/bin/sh

runFormula() {
  local VKPR_POSTGRES_VALUES=$(dirname "$0")/utils/postgres.yaml

  checkGlobalConfig $HA "false" "postgresql.HA" "HA"
  checkGlobalConfig "false" "false" "postgresql.metrics" "METRICS"
  checkGlobalConfig $VKPR_K8S_NAMESPACE "vkpr" "postgresql.namespace" "NAMESPACE"

  validatePostgresqlPassword $PASSWORD

  startInfos
  addRepoPostgres
  installPostgres
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Postgresql Install Routine")"
  echoColor "bold" "$(echoColor "blue" "Postgresql Password:") ${PASSWORD}"
  echoColor "bold" "$(echoColor "blue" "HA:") ${VKPR_ENV_HA}"
  echo "=============================="
}

addRepoPostgres(){
  registerHelmRepository bitnami https://charts.bitnami.com/bitnami
}

installPostgres(){
  echoColor "bold" "$(echoColor "green" "Installing Postgresql...")"
  local YQ_VALUES='.fullnameOverride = "postgres-postgresql"'
  local POSTGRESQL_CHART="postgresql"
  settingPostgres
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_POSTGRES_VALUES" \
  | $VKPR_HELM upgrade -i --version "$VKPR_POSTGRES_VERSION" \
      --create-namespace --namespace $VKPR_ENV_NAMESPACE \
      --wait -f - postgresql bitnami/$POSTGRESQL_CHART
}

settingPostgres() {
  if [[ $VKPR_ENV_HA = "true" ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .postgresql.username = "postgres" |
      .postgresql.database = "postgres" |
      .postgresql.password = "'$PASSWORD'" |
      .postgresql.repmgrUsername = "postgres" |
      .postgresql.repmgrPassword = "'$PASSWORD'" |
      .postgresql.repmgrDatabase = "postgres" |
      .postgresql.postgresPassword = "'$PASSWORD'" |
      .postgresql.replicaCount = 3 |
      .postgresql.podLabels.vkpr = "true" |
      .pgpool.adminUsername = "postgres" |
      .pgpool.adminPassword = "'$PASSWORD'" |
      .pgpool.replicaCount = 3 |
      .primary = {}
    '
    POSTGRESQL_CHART="postgresql-ha"
    else
    YQ_VALUES=''$YQ_VALUES' |
      .global.postgresql.postgresqlPassword = "'$PASSWORD'"
    '
    VKPR_POSTGRES_VERSION="10.12.3"
  fi
  
  if [[ $VKPR_ENV_METRICS == "true" ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .metrics.enabled = true |
      .metrics.serviceMonitor.enabled = true |
      .metrics.serviceMonitor.namespace = "'$VKPR_ENV_NAMESPACE'" |
      .metrics.serviceMonitor.interval = "1m" |
      .metrics.serviceMonitor.scrapeTimeout = "30m"
    '
    [[ $VKPR_ENV_HA = "true" ]] && YQ_VALUES=''$YQ_VALUES' | .metrics.serviceMonitor.selector.release = "prometheus-stack"' || YQ_VALUES=''$YQ_VALUES' | .metrics.serviceMonitor.additionalLabels.release = "prometheus-stack"'
  fi

  mergeVkprValuesHelmArgs "postgresql" $VKPR_POSTGRES_VALUES
}
# $VKPR_KUBECTL patch cm --namespace vkpr tcp-services -p '{"data": {"5432": "default/postgres-postgresql:5432"}}'