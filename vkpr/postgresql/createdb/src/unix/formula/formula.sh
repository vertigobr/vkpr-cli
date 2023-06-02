#!/usr/bin/env bash

runFormula() {
  startInfos
  local PG_PASSWORD PG_HOST;

  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "postgresql.namespace" "POSTGRESQL_NAMESPACE"

  if [[ $(checkPodName "$VKPR_ENV_POSTGRESQL_NAMESPACE" "postgres-postgresql") != "true" ]]; then
    error "Error, Postgresql doesn't up or installed yet"
    exit
  fi

  PG_PASSWORD=$($VKPR_JQ -r '.credential.password' "$VKPR_CREDENTIAL"/postgres)
  PG_HOST="postgres-postgresql"

  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    $VKPR_KUBECTL get pod | grep -q pgpool && PG_HOST="postgres-pgpool"
   else
    $VKPR_KUBECTL get pod -n "$VKPR_ENV_POSTGRESQL_NAMESPACE" | grep -q pgpool && PG_HOST="postgres-pgpool"
  fi

  info "Creating database $DBNAME in postgresql..."
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    $VKPR_KUBECTL run init-db --rm -it --restart="Never" \
      --image docker.io/bitnami/postgresql-repmgr:11.14.0-debian-10-r12 \
      --env="PGUSER=postgres" --env="PGPASSWORD=$PG_PASSWORD" --env="PGHOST=${PG_HOST}" --env="PGPORT=5432" --env="PGDATABASE=postgres" \
      --command -- psql -c '\x' -c "CREATE USER $DBUSER WITH ENCRYPTED PASSWORD '$DBPASSWORD';" \
                    -c "CREATE DATABASE $DBNAME;" -c "GRANT ALL PRIVILEGES ON DATABASE $DBNAME TO $DBUSER;" \
                    -c "ALTER DATABASE $DBNAME OWNER TO $DBUSER"
  else
    $VKPR_KUBECTL run init-db --rm -it --restart="Never" --namespace "$VKPR_ENV_POSTGRESQL_NAMESPACE" \
      --image docker.io/bitnami/postgresql-repmgr:11.14.0-debian-10-r12 \
      --env="PGUSER=postgres" --env="PGPASSWORD=$PG_PASSWORD" --env="PGHOST=${PG_HOST}" --env="PGPORT=5432" --env="PGDATABASE=postgres" \
      --command -- psql -c '\x' -c "CREATE USER $DBUSER WITH ENCRYPTED PASSWORD '$DBPASSWORD';" \
                    -c "CREATE DATABASE $DBNAME;" -c "GRANT ALL PRIVILEGES ON DATABASE $DBNAME TO $DBUSER;" \
                    -c "ALTER DATABASE $DBNAME OWNER TO $DBUSER"
  fi
  bold "=============================="

}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Postgresql createDb Routine"
  boldNotice "Database name: $DBNAME"
  boldNotice "Database user: $DBUSER"
  boldNotice "Database user's password: $DBPASSWORD"
  bold "=============================="
}
