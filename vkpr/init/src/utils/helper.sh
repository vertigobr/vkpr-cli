#!/bin/bash

# Create a variable by Global Scope
# $1: Global variable  /  $2: Default value of the global variable  /  $3: Label from config file  /  $4: Name of env
checkGlobalConfig(){
  FILE_LABEL=".global.$3"
  local NAME_ENV=VKPR_ENV_$4
  if [ -f "$VKPR_GLOBAL" ] && [ $1 == $2 ] && [[ $($VKPR_YQ eval $FILE_LABEL $VKPR_GLOBAL) != "null" ]]; then
      echoColor "yellow" "Setting value from config file"
      eval $NAME_ENV=$($VKPR_YQ eval $FILE_LABEL $VKPR_GLOBAL)
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

# Check if any Pod is already up to use and match with another tools
# $1: name of the pod
checkPodName(){
  for pod in $($VKPR_KUBECTL get pods -n $VKPR_K8S_NAMESPACE --ignore-not-found  | awk 'NR>1{print $1}'); do
    if [[ "$pod" == "$1"* ]]; then
      echo true  # pod name found a match, then returns True
      return
    fi
  done
  echo false
}

# Create a new instance of DB in Postgres;
# $1: Postgres User  /  $2: Postgres Password  /  $3: Name of DB to create
createDatabase(){
  local PG_HOST="postgres-postgresql"
  [[ ! -z $($VKPR_KUBECTL get pod -n $VKPR_K8S_NAMESPACE | grep pgpool) ]] && PG_HOST="postgres-postgresql-pgpool"
  $VKPR_KUBECTL run init-db --rm -it --restart="Never" --namespace $VKPR_K8S_NAMESPACE --image docker.io/bitnami/postgresql-repmgr:11.14.0-debian-10-r12 --env="PGUSER=$1" --env="PGPASSWORD=$2" --env="PGHOST=${PG_HOST}" --env="PGPORT=5432" --env="PGDATABASE=postgres" --command -- psql --command="CREATE DATABASE $3"
}

# Check if exist some instace of DB with specified name in Postgres
# $1: Postgres User  /  $2: Postgres Password  /  $3: Name of DB to search
checkExistingDatabase(){
  local PG_HOST="postgres-postgresql"
  [[ ! -z $($VKPR_KUBECTL get pod -n $VKPR_K8S_NAMESPACE | grep pgpool) ]] && PG_HOST="postgres-postgresql-pgpool"
  $VKPR_KUBECTL run check-db --rm -it --restart='Never' --namespace $VKPR_K8S_NAMESPACE --image docker.io/bitnami/postgresql-repmgr:11.14.0-debian-10-r12 --env="PGUSER=$1" --env="PGPASSWORD=$2" --env="PGHOST=${PG_HOST}" --env="PGPORT=5432" --env="PGDATABASE=postgres" --command -- psql -lqt | cut -d \| -f 1 | grep $3 | sed -e 's/^[ \t]*//'
}

##Register new repository when url does not exists in helm
#param1: repository name
#param2: repository url
registerHelmRepository(){
  local REPO_NAME=$1; REPO_URL=$2
  
  #Checking by url because is not an unique column
  local RESULT=$(${VKPR_HELM} repo list -o json | ${VKPR_JQ} -r '.[] | select(.url == "'${REPO_URL}'").name')
  if [[ -z "${RESULT}" ]];then
    echo "Adding repository ${REPO_NAME}"
    ${VKPR_HELM} repo add ${REPO_NAME} ${REPO_URL} --force-update
  else
    echoColor green "Repository ${REPO_NAME} already configured."
  fi
  
}

## Merge KV helmArgs from VKPR with the indicated value application
#param1: key value from the application in vkpr yaml
#param2: value files from the application
mergeVkprValuesHelmArgs() {
  [[ ! -f $VKPR_GLOBAL ]] && return
  if [[ $($VKPR_YQ eval '.global.'${1}' | has ("helmArgs")' $CURRENT_PWD/vkpr.yaml) == true ]]; then
    cp $CURRENT_PWD/vkpr.yaml $(dirname "$0")/vkpr-cp.yaml
    for i in $($VKPR_YQ eval '.global.'${1}'.helmArgs | keys' $CURRENT_PWD/vkpr.yaml | cut -d " " -f2); do
      $VKPR_YQ eval-all -i '. * {"'${i}'": select(fileIndex==1).global.'${1}'.helmArgs.'${i}'} | select(fileIndex==0)' $2 $(dirname "$0")/vkpr-cp.yaml
    done
    rm $(dirname "$0")/vkpr-cp.yaml
  fi
}

##Encode text
rawUrlEncode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"    # You can either set a return variable (FASTER) 
  REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}