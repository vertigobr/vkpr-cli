#!/bin/bash

# Create a variable by Global Scope
# $1: Global variable  /  $2: Default value of the global variable  /  $3: Label from config file  /  $4: Name of env
checkGlobalConfig(){
  VALUES_FILE=~/.vkpr/global-values.yaml
  FILE_LABEL=".global.$3"
  local NAME_ENV=VKPR_ENV_$4
  if [ -f "$VALUES_FILE" ] && [ $1 == $2 ] && [ $($VKPR_YQ eval $FILE_LABEL $VALUES_FILE) != "null" ]; then
      echoColor "yellow" "Setting value from config file"
      eval $NAME_ENV=$($VKPR_YQ eval $FILE_LABEL $VALUES_FILE)
  else
    if [ $1 == $2 ]; then
      echoColor "yellow" "Setting value from default value"
      eval $NAME_ENV=$1
    else
      echoColor "yellow" "Setting value from user input"
      eval $NAME_ENV=$1
    fi
  fi
}

checkGlobal() {
  local VALUE_CONTENT=`$VKPR_YQ eval ".global.${1}" $VKPR_GLOBAL`
  if [[ $3 != "" ]]; then
    VALUE_CONTENT=`$VKPR_YQ eval '{"'$3'": .global.'$1'}' $VKPR_GLOBAL`
  fi
  if [[ $VALUE_CONTENT != "null" ]]; then
    echo "$VALUE_CONTENT" >> $2
  fi
}

# Create a new instance of DB in Postgres;
# $1: Postgres User  /  $2: Postgres Password  /  $3: Name of DB to create
createDatabase(){
  $VKPR_KUBECTL run init-db --rm -it --restart="Never" --image docker.io/bitnami/postgresql:11.13.0-debian-10-r0 --env="PGUSER=$1" --env="PGPASSWORD=$2" --env="PGHOST=vkpr-postgres-postgresql" --env="PGPORT=5432" --env="PGDATABASE=postgres" --command -- psql --command="CREATE DATABASE $3"
}

# Check if exist some instace of DB with specified name in Postgres
# $1: Postgres User  /  $2: Postgres Password  /  $3: Name of DB to search
checkExistingDatabase(){
  $VKPR_KUBECTL run check-db --rm -it --restart='Never' --image docker.io/bitnami/postgresql:11.13.0-debian-10-r12 --env="PGUSER=$1" --env="PGPASSWORD=$2" --env="PGHOST=vkpr-postgres-postgresql" --env="PGPORT=5432" --env="PGDATABASE=postgres" --command -- psql -lqt | cut -d \| -f 1 | grep $3 | sed -e 's/^[ \t]*//'
}

checkExistingPostgres(){
  local EXISTING_POSTGRES=$($VKPR_KUBECTL get sts vkpr-postgres-postgresql -o name --ignore-not-found | cut -d "/" -f2)
  if [[ $EXISTING_POSTGRES = "vkpr-postgres-postgresql" ]]; then
    echo "true"
    return
  fi
  echo "false"
}

checkExistingLoki() {
  local EXISTING_LOKI=$($VKPR_KUBECTL get sts vkpr-loki-stack -o name --ignore-not-found | cut -d "/" -f 2)
  if [[ $EXISTING_LOKI = "vkpr-loki-stack" ]]; then
    echo "true"
    return
  fi
  echo "false"
}

checkExistingGrafana() {
  local EXISTING_GRAFANA=$($VKPR_KUBECTL get deploy vkpr-prometheus-stack-grafana -o name --ignore-not-found | cut -d "/" -f 2)
  if [[ $EXISTING_GRAFANA = "vkpr-prometheus-stack-grafana" ]]; then
    echo "true"
    return
  fi
  echo "false"
}

checkExistingKeycloak() {
  local EXISTING_LOKI=$($VKPR_KUBECTL get sts vkpr-keycloak -o name --ignore-not-found | cut -d "/" -f 2)
  if [[ $EXISTING_LOKI = "vkpr-keycloak" ]]; then
    echo "true"
    return
  fi
  echo "false"
}