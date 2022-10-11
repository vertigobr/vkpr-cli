#!/usr/bin/env bash

createDbPostgresql() {

  local PG_PASSWORD PG_HOST;

  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "postgresql.namespace" "POSTGRESQL_NAMESPACE"
  checkGlobalConfig "" "" "postgresql.commands.createDb.name" "DB_NAME"
  checkGlobalConfig "" "" "postgresql.commands.createDb.user" "DB_USER"
  checkGlobalConfig "" "" "postgresql.commands.createDb.password" "DB_PASSWORD"

  validatePostgresqlNamespace "$VKPR_ENV_POSTGRESQL_NAMESPACE"
  validateDbName "$VKPR_ENV_DB_NAME"
  validateDbUser "$VKPR_ENV_DB_USER"
  validateDbPassword "$VKPR_ENV_DB_PASSWORD"

  if [[ $(checkPodName "$VKPR_ENV_POSTGRESQL_NAMESPACE" "postgres-postgresql") != "true" ]]; then
    error "Error, Postgresql doesn't up or installed yet"
    exit
  fi

  PG_PASSWORD=$($VKPR_JQ -r '.credential.password' "$VKPR_CREDENTIAL"/postgres)

  PG_HOST="postgres-postgresql"
  $VKPR_KUBECTL get pod -n "$VKPR_ENV_POSTGRESQL_NAMESPACE" | grep -q pgpool && PG_HOST="postgres-pgpool"

  info "Creating database $VKPR_ENV_DB_NAME in postgresql..."
  $VKPR_KUBECTL run init-db --rm -it --restart="Never" --namespace "$VKPR_ENV_POSTGRESQL_NAMESPACE" \
    --image docker.io/bitnami/postgresql-repmgr:11.14.0-debian-10-r12 \
    --env="PGUSER=postgres" --env="PGPASSWORD=$PG_PASSWORD" --env="PGHOST=${PG_HOST}" --env="PGPORT=5432" --env="PGDATABASE=postgres" \
    --command -- psql -c '\x' -c "CREATE USER $VKPR_ENV_DB_USER WITH ENCRYPTED PASSWORD '$VKPR_ENV_DB_PASSWORD';" \
                  -c "CREATE DATABASE $VKPR_ENV_DB_NAME;" -c "GRANT ALL PRIVILEGES ON DATABASE $VKPR_ENV_DB_NAME TO $VKPR_ENV_DB_USER" > /dev/null

  boldInfo "Done!"
}
