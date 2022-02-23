#!/bin/bash

runFormula() {
  echoColor "bold" "$(echoColor "green" "Creating database $DBNAME in postgresql...")"
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "postgresql.namespace" "POSTGRESQL_NAMESPACE"

  local PG_PASSWORD; PG_PASSWORD=$($VKPR_JQ -r '.credential.password' ~/.rit/credentials/default/postgres)
  local PG_HOST; PG_HOST="postgres-postgresql"

  if [[ $(checkPodName "$VKPR_ENV_POSTGRESQL_NAMESPACE" "postgres-postgresql") == "true" ]]; then
    $VKPR_KUBECTL get pod -n "$VKPR_ENV_POSTGRESQL_NAMESPACE" | grep -q pgpool && PG_HOST="postgres-postgresql-pgpool"

    $VKPR_KUBECTL run init-db --rm -it --restart="Never" --namespace "$VKPR_ENV_POSTGRESQL_NAMESPACE" \
      --image docker.io/bitnami/postgresql-repmgr:11.14.0-debian-10-r12 \
      --env="PGUSER=postgres" --env="PGPASSWORD=$PG_PASSWORD" --env="PGHOST=${PG_HOST}" --env="PGPORT=5432" --env="PGDATABASE=postgres" \
      --command -- psql -c '\x' -c "CREATE USER $DBUSER WITH ENCRYPTED PASSWORD '$DBPASSWORD';" \
                    -c "CREATE DATABASE $DBNAME;" -c "GRANT ALL PRIVILEGES ON DATABASE $DBNAME TO $DBUSER"
    else
    echoColor "red" "Error, Postgresql doesn't up or installed yet"
  fi
}
