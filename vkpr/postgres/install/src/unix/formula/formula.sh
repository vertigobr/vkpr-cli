#!/bin/sh

runFormula() {
  VKPR_POSTGRES_VALUES=$(dirname "$0")/utils/postgres.yaml

  addRepoPostgres
  installPostgres
}

addRepoPostgres(){
  $VKPR_HELM repo add bitnami https://charts.bitnami.com/bitnami
  $VKPR_HELM repo update
}

installPostgres(){
  echoColor "yellow" "Installing postgres..."
  $VKPR_HELM upgrade -i --set global.postgresql.postgresqlPassword=$PASSWORD --set volumePermissions.enabled=true vkpr-postgres bitnami/postgresql
}