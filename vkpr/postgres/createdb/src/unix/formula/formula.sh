#!/bin/bash

runFormula() {
  echoColor "bold" "$(echoColor "green" "Creating database $DBNAME in postgresql...")"
  local PG_PASSWORD=$($VKPR_JQ -r '.credential.password' ~/.rit/credentials/default/postgres)
  local PG_HOST="postgres-postgresql"
  if [[ $(checkPodName "postgres-postgresql") = "true" ]]; then
    [[ ! -z $($VKPR_KUBECTL get pod -n $VKPR_K8S_NAMESPACE | grep pgpool) ]] && PG_HOST="postgres-postgresql-pgpool"
    $VKPR_KUBECTL run init-db --rm -it --restart="Never" --namespace $VKPR_K8S_NAMESPACE --image docker.io/bitnami/postgresql-repmgr:11.14.0-debian-10-r12 --env="PGUSER=postgres" --env="PGPASSWORD=$PG_PASSWORD" --env="PGHOST=${PG_HOST}" --env="PGPORT=5432" --env="PGDATABASE=postgres" \
    --command -- psql -c '\x' -c "CREATE USER $DBUSER WITH ENCRYPTED PASSWORD '$DBPASSWORD';" -c "CREATE DATABASE $DBNAME;" -c "GRANT ALL PRIVILEGES ON DATABASE $DBNAME TO $DBUSER"
    else
    echoColor "red" "Error, Postgresql doesn't up or installed yet"
  fi
}
