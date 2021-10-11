#!/bin/sh

runFormula() {
  local VKPR_POSTGRES_VALUES=$(dirname "$0")/utils/postgres.yaml

  checkGlobal "postgres.resources" $VKPR_POSTGRES_VALUES "resources"
  checkGlobal "postgres.extraEnv" $VKPR_POSTGRES_VALUES

  addRepoPostgres
  installPostgres
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Postgresql Install Routine")"
  echoColor "bold" "$(echoColor "blue" "Postgresql Password:") ${PASSWORD}"
  echo "=============================="
}

addRepoPostgres(){
  registerHelmRepository bitnami https://charts.bitnami.com/bitnami
}

installPostgres(){
  echoColor "green" "Installing postgres..."

  local YQ_VALUES='.global.postgresql.postgresqlPassword = "'$PASSWORD'"'
  settingPostgres
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_POSTGRES_VALUES" \
  | $VKPR_HELM upgrade -i --version "$VKPR_POSTGRES_VERSION" \
      --create-namespace --namespace $VKPR_K8S_NAMESPACE \
      --wait -f - postgres bitnami/postgresql 
}

settingPostgres() {
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