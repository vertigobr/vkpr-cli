#!/bin/bash

runFormula() {
  local PG_PASSWORD=$($VKPR_JQ -r '.credential.password' ~/.rit/credentials/default/postgres)
  if [[ $(checkPodName "postgres-postgresql") = "true" ]]; then
    $VKPR_KUBECTL run init-db --rm -it --restart="Never" --namespace $VKPR_K8S_NAMESPACE --image docker.io/bitnami/postgresql:11.13.0-debian-10-r0 --env="PGUSER=postgres" --env="PGPASSWORD=$PG_PASSWORD" --env="PGHOST=postgres-postgresql" --env="PGPORT=5432" --env="PGDATABASE=postgres" \
    --command -- psql -c '\x' -c "CREATE USER $DBUSER WITH ENCRYPTED PASSWORD '$DBPASSWORD';" -c "CREATE DATABASE $DBNAME;" -c "GRANT ALL PRIVILEGES ON DATABASE $DBNAME TO $DBUSER"
    else
    echoColor "red" "Error, Postgresql doesn't up or installed yet"
  fi
}
