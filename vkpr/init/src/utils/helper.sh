#!/bin/bash

verifyExistingEnv(){
  aux=0
  for i in "$@"
  do
    if [ -z $(cat $VKPR_GLOBALS/.env | grep $i) ]; then
      if (( $aux % 2 == 0 )); then
        printf "VKPR_ENV_${i}=" >> $VKPR_GLOBALS/.env
        else
        printf "${i}\n" >> $VKPR_GLOBALS/.env
      fi
      let "aux++"
    fi
  done
}

createDatabase(){
  $VKPR_KUBECTL run init-db --rm -it --restart="Never" --image docker.io/bitnami/postgresql:11.13.0-debian-10-r0 --env="PGUSER=$1" --env="PGPASSWORD=$2" --env="PGHOST=postgres-postgresql" --env="PGPORT=5432" --env="PGDATABASE=postgres" --command -- psql --command="CREATE DATABASE $3"
}

checkExistingDatabase(){
  $VKPR_KUBECTL run check-db --rm -it --restart='Never' --image docker.io/bitnami/postgresql:11.13.0-debian-10-r12 --env="PGUSER=$1" --env="PGPASSWORD=$2" --env="PGHOST=postgres-postgresql" --env="PGPORT=5432" --env="PGDATABASE=postgres" --command -- psql -lqt | cut -d \| -f 1 | grep $3 | sed -e 's/^[ \t]*//'
}