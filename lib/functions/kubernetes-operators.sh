#!/usr/bin/env bash

## Check if any Pod is already up to use and match with another tools
# Parameters:
# 1 - POD_NAMESPACE
# 2 - POD_NAME
checkPodName(){
  local POD_NAMESPACE="$1" POD_NAME="$2"
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    for pod in $($VKPR_KUBECTL get pods --ignore-not-found  | awk 'NR>1{print $1}'); do
      if [[ "$pod" == "$POD_NAME"* ]]; then
        echo true  # pod name found a match, then returns True
        return
      fi
    done
  else
    for pod in $($VKPR_KUBECTL get pods -n "$POD_NAMESPACE" --ignore-not-found  | awk 'NR>1{print $1}'); do
      if [[ "$pod" == "$POD_NAME"* ]]; then
        echo true  # pod name found a match, then returns True
        return
      fi
    done
  fi
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

  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then 
      $VKPR_KUBECTL run init-db --rm -it --restart="Never" \
    --image docker.io/bitnami/postgresql-repmgr:11.14.0-debian-10-r12 \
    --env="PGUSER=$PG_USER" --env="PGPASSWORD=$PG_PASSWORD" --env="PGHOST=${PG_HOST}" --env="PGPORT=5432" --env="PGDATABASE=postgres" \
    --command -- psql --command="CREATE DATABASE $DATABASE_NAME"
  else 
    $VKPR_KUBECTL run init-db --rm -it --restart="Never" --namespace "$NAMESPACE" \
    --image docker.io/bitnami/postgresql-repmgr:11.14.0-debian-10-r12 \
    --env="PGUSER=$PG_USER" --env="PGPASSWORD=$PG_PASSWORD" --env="PGHOST=${PG_HOST}" --env="PGPORT=5432" --env="PGDATABASE=postgres" \
    --command -- psql --command="CREATE DATABASE $DATABASE_NAME"
  fi
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

  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then 
    $VKPR_KUBECTL run -q check-db --rm -it --restart='Never'\
    --image docker.io/bitnami/postgresql-repmgr:11.14.0-debian-10-r12 \
    --env="PGUSER=$PG_USER" --env="PGPASSWORD=$PG_PASSWORD" --env="PGHOST=${PG_HOST}" --env="PGPORT=5432" --env="PGDATABASE=postgres" \
    --command -- psql -lqt | cut -d \| -f 1 | grep "$DATABASE_NAME" | sed -e 's/^[ \t]*//'
  else 
    $VKPR_KUBECTL run -q check-db --rm -it --restart='Never' --namespace "$NAMESPACE" \
      --image docker.io/bitnami/postgresql-repmgr:11.14.0-debian-10-r12 \
      --env="PGUSER=$PG_USER" --env="PGPASSWORD=$PG_PASSWORD" --env="PGHOST=${PG_HOST}" --env="PGPORT=5432" --env="PGDATABASE=postgres" \
      --command -- psql -lqt | cut -d \| -f 1 | grep "$DATABASE_NAME" | sed -e 's/^[ \t]*//'
  fi 
}

createGrafanaDashboard() {
  local DASHBOARD_FILE=$1 GRAFANA_NAMESPACE=$2

  LOGIN_GRAFANA=$($VKPR_KUBECTL get secret --namespace "$GRAFANA_NAMESPACE" prometheus-stack-grafana -o=jsonpath="{.data.admin-user}" | base64 -d)
  PWD_GRAFANA=$($VKPR_KUBECTL get secret --namespace "$GRAFANA_NAMESPACE" prometheus-stack-grafana -o=jsonpath="{.data.admin-password}" | base64 -d)

  echo "{}" | $VKPR_JQ --argjson dashboardContent "$(<$1)" '.dashboard += $dashboardContent | (.dashboard.id, .dashboard.uid) = null' > /tmp/dashboard-grafana.json

  GRAFANA_ADDRESS="grafana.${VKPR_ENV_GLOBAL_DOMAIN}"
  [[ $VKPR_ENV_GLOBAL_DOMAIN == "localhost" ]] && GRAFANA_ADDRESS="grafana.localhost:8000"
  debug "GRAFANA ADDRESS = $GRAFANA_ADDRESS"
  CREATE_DASHBOARD=$(curl -s -X POST -H "Content-Type: application/json" \
    -d @/tmp/dashboard-grafana.json http://$LOGIN_GRAFANA:$PWD_GRAFANA@$GRAFANA_ADDRESS/api/dashboards/db |\
    $VKPR_JQ -r '.status' -
  )
  
  debug "STATUS = $CREATE_DASHBOARD"

  if [[ $CREATE_DASHBOARD == "name-exists" ]]; then
    error "Dashboard with same name already exists"
    return
  fi

  if [[ $CREATE_DASHBOARD == "" ]]; then
    error "Unreachable grafana api"
    return
  fi

  if [[ $CREATE_DASHBOARD == "null" ]]; then
    error "Dashboard may contain errors"
    return
  fi

  info "Dashboard to prometheus metrics created"
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

execScriptsOnPod() {
  local SCRIPT_PATH=$1 POD_NAME=$2 \
    POD_NAMESPACE=$3

  $VKPR_KUBECTL cp "$SCRIPT_PATH" "$POD_NAME":tmp/script.sh -n "$POD_NAMESPACE"
  $VKPR_KUBECTL exec -it "$POD_NAME" -n "$POD_NAMESPACE" -- sh -c "
    chmod +x /tmp/script.sh && \
    sh /tmp/script.sh && \
    rm /tmp/script.sh
  "
}

## Remove secrets of a specific application from kubernetes cluster
# Parameters:
# 1 - APP_NAME
# 2 - APP_NAMESPACE
secretRemove (){
  local APP_NAME=$1 \
        APP_NAMESPACE=$2 \
        STD_OUT

  info "Removing $APP_NAME secrets..."    
  for secret in $($VKPR_KUBECTL get secret -n $APP_NAMESPACE -l app.kubernetes.io/managed-by=vkpr 2> /dev/null | awk 'NR>1{print $1}' | grep $APP_NAME) 
  do
    STD_OUT=$($VKPR_KUBECTL delete secret/$secret -n $APP_NAMESPACE 2> /dev/null)
    debug $STD_OUT
  done
  echo "secrets from \"$APP_NAME\" have been removed"
}