#!/bin/sh

runFormula() {
  VKPR_POSTGRES_VALUES=$(dirname "$0")/utils/postgres.yaml

  addRepoPostgres
  installPostgres
}

addRepoPostgres(){
  registerHelmRepository bitnami https://charts.bitnami.com/bitnami
}

installPostgres(){
  echoColor "yellow" "Installing postgres..."

  $VKPR_HELM upgrade -i \
    --create-namespace --namespace $VKPR_K8S_NAMESPACE \
    --set global.postgresql.postgresqlPassword=$PASSWORD \
    --set volumePermissions.enabled=true \
    --wait postgres bitnami/postgresql 
    
}

# $VKPR_KUBECTL patch cm --namespace vkpr tcp-services -p '{"data": {"5432": "default/postgres-postgresql:5432"}}'