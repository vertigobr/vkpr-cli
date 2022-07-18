#!/usr/bin/env bash

## Check if any Pod is already up to use and match with another tools
# Parameters:
# 1 - POD_NAMESPACE
# 2 - POD_NAME
checkPodName(){
  local POD_NAMESPACE="$1" POD_NAME="$2"

  for pod in $($VKPR_KUBECTL get pods -n "$POD_NAMESPACE" --ignore-not-found  | awk 'NR>1{print $1}'); do
    if [[ "$pod" == "$POD_NAME"* ]]; then
      echo true  # pod name found a match, then returns True
      return
    fi
  done
  echo false
}

checkSecretName(){
  local SECRET_NAMESPACE="$1" SECRET_NAME="$2"

  for secret in $($VKPR_KUBECTL get secrets -n "$SECRET_NAMESPACE" --ignore-not-found  | awk 'NR>1{print $1}'); do
    if [[ "$secret" == "$SECRET_NAME"* ]]; then
      echo true  # secret name found a match, then returns True
      return
    fi
  done
  echo false
}

## Create a new Postgresql database
# Parameters:
# 1 - POSTGRESQL_USER
# 2 - POSTGRESQL_PASSWORD
# 3 - DATABASE_NAME
# 4 - POSTGRESQL_POD_NAMESPACE
createDatabase(){
  local PG_USER="$1" PG_HOST="$2" PG_PASSWORD="$3" \
        DATABASE_NAME="$4" NAMESPACE="$5"

  $VKPR_KUBECTL run init-db --rm -it --restart="Never" --namespace "$NAMESPACE" \
    --image docker.io/bitnami/postgresql-repmgr:11.14.0-debian-10-r12 \
    --env="PGUSER=$PG_USER" --env="PGPASSWORD=$PG_PASSWORD" --env="PGHOST=${PG_HOST}" --env="PGPORT=5432" --env="PGDATABASE=postgres" \
    --command -- psql --command="CREATE DATABASE $DATABASE_NAME"
}

## Check if there is any database with specific name in Postgres
# Parameters:
# 1 - POSTGRESQL_USER
# 2 - POSTGRESQL_PASSWORD
# 3 - DATABASE_NAME
# 4 - POSTGRESQL_POD_NAMESPACE
checkExistingDatabase() {
  local PG_USER="$1" PG_HOST="$2" PG_PASSWORD="$3" \
        DATABASE_NAME="$4" NAMESPACE="$5"

  $VKPR_KUBECTL run check-db --rm -it --restart='Never' --namespace "$NAMESPACE" \
    --image docker.io/bitnami/postgresql-repmgr:11.14.0-debian-10-r12 \
    --env="PGUSER=$PG_USER" --env="PGPASSWORD=$PG_PASSWORD" --env="PGHOST=${PG_HOST}" --env="PGPORT=5432" --env="PGDATABASE=postgres" \
    --command -- psql -lqt | cut -d \| -f 1 | grep "$DATABASE_NAME" | sed -e 's/^[ \t]*//'
}

createGrafanaDashboard() {
  local DASHBOARD_NAME=$1 DASHBOARD_FILE=$2 NAMESPACE=$3

  $VKPR_KUBECTL create cm $DASHBOARD_NAME-grafana --from-file="$DASHBOARD_FILE" --dry-run=client -o yaml |\
    $VKPR_YQ eval ".metadata.labels.app = \"$DASHBOARD_NAME\" |
      .metadata.labels.grafana_dashboard = \"1\" |
      .metadata.labels.release = \"prometheus-stack\" |
      .metadata.labels.[\"app.kubernetes.io/managed-by\"] = \"vkpr\"" - | $VKPR_KUBECTL apply -n $3 -f -
}

createAWSCredentialSecret() {
  if [[ $(checkSecretName $1 "vkpr-aws-credential") == true ]]; then
    notice "Using already created vkpr-aws-credential"
    return
  fi

  $VKPR_KUBECTL create secret generic vkpr-aws-credential -n $1 \
    --from-literal=access-key=$2 \
    --from-literal=secret-key=$3 \
    --from-literal=region=$4
}

createDOCredentialSecret() {
  if [[ $(checkSecretName $1 "vkpr-do-credential") == true ]]; then
    notice "Using already created vkpr-do-credential"
    return
  fi

  $VKPR_KUBECTL create secret generic vkpr-do-credential -n $1 --from-literal=api-token=$2
}
