#!/bin/bash

runFormula() {
  # Global values
  checkGlobalConfig "" "" "global.provider" "GLOBAL_PROVIDER"
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "global.namespace" "GLOBAL_NAMESPACE"
  checkGlobalConfig "nginx" "nginx" "global.ingressClassName" "GLOBAL_INGRESS"

  # App values
  checkGlobalConfig "$HA" "false" "postgresql.HA" "POSTGRESQL_HA"
  checkGlobalConfig "false" "false" "postgresql.metrics" "POSTGRESQL_METRICS"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "postgresql.namespace" "POSTGRESQL_NAMESPACE"

  validatePostgresqlPassword "$PASSWORD"
  validateHA "$VKPR_ENV_POSTGRESQL_HA"
  validatePostgresqlMetrics "$VKPR_ENV_POSTGRESQL_METRICS"

  local VKPR_POSTGRES_VALUES; VKPR_POSTGRES_VALUES=$(dirname "$0")/utils/postgres.yaml
  local HELM_ARGS="--namespace $VKPR_ENV_POSTGRES_NAMESPACE --create-namespace"

  startInfos
  addRepoPostgres
  installPostgres
}

startInfos() {
  echo "=============================="
  info "VKPR Postgresql Install Routine"
  notice "Postgresql Password: ${PASSWORD}"
  notice "HA: ${VKPR_ENV_POSTGRESQL_HA}"
  echo "=============================="
}

addRepoPostgres(){
  registerHelmRepository bitnami https://charts.bitnami.com/bitnami
}

installPostgres(){
  local YQ_VALUES='.fullnameOverride = "postgres-postgresql"' \
    POSTGRESQL_CHART="postgresql"
  settingPostgres

  if [[ $DRY_RUN == true ]]; then
    bold "---"
    $VKPR_YQ eval "$YQ_VALUES" "$VKPR_POSTGRES_VALUES"
    mergeVkprValuesHelmArgs "postgresql" "$VKPR_POSTGRES_VALUES"    
  else
    info "Installing Postgresql..."
    $VKPR_YQ eval -i "$YQ_VALUES" "$VKPR_POSTGRES_VALUES"
    mergeVkprValuesHelmArgs "postgresql" "$VKPR_POSTGRES_VALUES"
    # shellcheck disable=SC2086
    $VKPR_HELM upgrade -i --version "$VKPR_POSTGRES_VERSION" \
        $HELM_ARGS \
      --wait -f "$VKPR_POSTGRES_VALUES" postgresql bitnami/$POSTGRESQL_CHART
  fi
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
      .global.postgresql.auth.password = \"$PASSWORD\"
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
  settingPostgresProvider
}

settingPostgresProvider(){
  ACTUAL_CONTEXT=$($VKPR_KUBECTL config get-contexts --no-headers | grep "\*" | xargs | awk -F " " '{print $2}')
  if [[ "$VKPR_ENV_GLOBAL_PROVIDER" == "okteto" ]] || [[ $ACTUAL_CONTEXT == "cloud_okteto_com" ]]; then   
    HELM_ARGS=""
  fi  
}