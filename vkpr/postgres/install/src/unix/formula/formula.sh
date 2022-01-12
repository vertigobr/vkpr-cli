#!/bin/sh

runFormula() {
  local VKPR_POSTGRES_VALUES=$(dirname "$0")/utils/postgres.yaml

  checkGlobalConfig $HA "false" "postgresql.HA" "HA"
  checkGlobalConfig $PASSWORD "postgres" "postgresql.password" "POSTGRES_PASSWORD"
  checkGlobalConfig "false" "false" "postgresql.metrics" "METRICS"

  startInfos
  addRepoPostgres
  installPostgres
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Postgresql Install Routine")"
  echoColor "bold" "$(echoColor "blue" "Postgresql Password:") ${VKPR_ENV_POSTGRES_PASSWORD}"
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
      --create-namespace --namespace $VKPR_K8S_NAMESPACE \
      --wait -f - postgresql bitnami/$POSTGRESQL_CHART
}

settingPostgres() {
  if [[ $VKPR_ENV_HA = "true" ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .postgresql.username = "postgres" |
      .postgresql.database = "postgres" |
      .postgresql.password = "'$VKPR_ENV_POSTGRES_PASSWORD'" |
      .postgresql.repmgrUsername = "postgres" |
      .postgresql.repmgrPassword = "'$VKPR_ENV_POSTGRES_PASSWORD'" |
      .postgresql.repmgrDatabase = "postgres" |
      .postgresql.postgresPassword = "'$VKPR_ENV_POSTGRES_PASSWORD'" |
      .postgresql.replicaCount = 3 |
      .pgpool.adminUsername = "postgres" |
      .pgpool.adminPassword = "'$VKPR_ENV_POSTGRES_PASSWORD'" |
      .pgpool.replicaCount = 3
    '
    POSTGRESQL_CHART="postgresql-ha"
    else
    YQ_VALUES=''$YQ_VALUES' |
      .global.postgresql.postgresqlPassword = "'$VKPR_ENV_POSTGRES_PASSWORD'"
    '
    VKPR_POSTGRES_VERSION="10.12.3"
  fi
  
  if [[ $VKPR_ENV_METRICS == "true" ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .metrics.enabled = true |
      .metrics.serviceMonitor.enabled = true |
      .metrics.serviceMonitor.namespace = "vkpr" |
      .metrics.serviceMonitor.interval = "1m" |
      .metrics.serviceMonitor.scrapeTimeout = "30m"
    '
    [[ $VKPR_ENV_HA = "true" ]] && YQ_VALUES=''$YQ_VALUES' | .metrics.serviceMonitor.selector.release = "prometheus-stack"' || YQ_VALUES=''$YQ_VALUES' | .metrics.serviceMonitor.additionalLabels.release = "prometheus-stack"'
  fi

  mergeVkprValuesHelmArgs "postgresql" $VKPR_POSTGRES_VALUES
}
# $VKPR_KUBECTL patch cm --namespace vkpr tcp-services -p '{"data": {"5432": "default/postgres-postgresql:5432"}}'