#!/bin/bash

# Create a variable by Global Scope
# $1: Global variable  /  $2: Default value of the global variable  /  $3: Label from config file  /  $4: Name of env
checkGlobalConfig(){
  CONFIG_FILE=~/.vkpr/global-config.yaml
  FILE_LABEL=".global.$3"
  local NAME_ENV=VKPR_ENV_$4
  if [ -f "$CONFIG_FILE" ] && [ $1 == $2 ] && [ $($VKPR_YQ eval $FILE_LABEL $CONFIG_FILE) != "null" ]; then
      echoColor "yellow" "Setting value from config file"
      eval $NAME_ENV=$($VKPR_YQ eval $FILE_LABEL $CONFIG_FILE)
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

# Create a new instance of DB in Postgres;
# $1: Postgres User  /  $2: Postgres Password  /  $3: Name of DB to create
createDatabase(){
  $VKPR_KUBECTL run init-db --rm -it --restart="Never" --image docker.io/bitnami/postgresql:11.13.0-debian-10-r0 --env="PGUSER=$1" --env="PGPASSWORD=$2" --env="PGHOST=postgres-postgresql" --env="PGPORT=5432" --env="PGDATABASE=postgres" --command -- psql --command="CREATE DATABASE $3"
}

# Check if exist some instace of DB with specified name in Postgres
# $1: Postgres User  /  $2: Postgres Password  /  $3: Name of DB to search
checkExistingDatabase(){
  $VKPR_KUBECTL run check-db --rm -it --restart='Never' --image docker.io/bitnami/postgresql:11.13.0-debian-10-r12 --env="PGUSER=$1" --env="PGPASSWORD=$2" --env="PGHOST=postgres-postgresql" --env="PGPORT=5432" --env="PGDATABASE=postgres" --command -- psql -lqt | cut -d \| -f 1 | grep $3 | sed -e 's/^[ \t]*//'
}