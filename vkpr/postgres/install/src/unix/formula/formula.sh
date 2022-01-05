#!/bin/sh

runFormula() {
  local VKPR_POSTGRES_VALUES=$(dirname "$0")/utils/postgres.yaml

  checkGlobalConfig $HA "false" "postgresql.HA" "HA"
  checkGlobalConfig $PASSWORD "postgres" "postgresql.password" "POSTGRES_PASSWORD"
  #checkGlobal "postgresql.resources" $VKPR_POSTGRES_VALUES "resources"
  #checkGlobal "postgresql.extraEnv" $VKPR_POSTGRES_VALUES

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
  echoColor "green" "Installing postgres..."

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
  
  if [[ $(checkPodName "prometheus-prometheus-stack-kube-prom-prometheus") == "true" ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .metrics.enabled = true |
      .metrics.serviceMonitor.enabled = true |
      .metrics.serviceMonitor.namespace = "vkpr" |
      .metrics.serviceMonitor.interval = "1m" |
      .postgresqlDatabase = "grafana-metrics"
    '
  fi
}
# $VKPR_KUBECTL patch cm --namespace vkpr tcp-services -p '{"data": {"5432": "default/postgres-postgresql:5432"}}'