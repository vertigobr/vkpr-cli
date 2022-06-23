#!/usr/bin/env bash

## Creates a variable with the value that follows the stipulated precedence
## formula input -> values file -> env -> default values
# Parameters:
# 1 - INPUT_VALUE
# 2 - DEFAULT_INPUT_VALUE
# 3 - VALUES_LABEL_PATH
# 4 - ENV_NAME
checkGlobalConfig(){
  local INPUT_VALUE="$1" DEFAULT_INPUT_VALUE="$2" \
        VALUES_LABEL_PATH=".$3" ENV_NAME="VKPR_ENV_$4"

  if [ "$INPUT_VALUE" != "$DEFAULT_INPUT_VALUE" ]; then
    warn "Setting value from input value"
    eval "$ENV_NAME"="$INPUT_VALUE"
    return
  fi

  if [ -f "$VKPR_FILE" ] && [ "$($VKPR_YQ eval "$VALUES_LABEL_PATH" "$VKPR_FILE")" != "null" ]; then
    warn "Setting value from config file"
    eval "$ENV_NAME"="$($VKPR_YQ eval "$VALUES_LABEL_PATH" "$VKPR_FILE")"
    return
  fi

  if printenv | grep -q "$ENV_NAME"; then
    warn "Setting value from env"
    eval "$ENV_NAME"="$(printf '%s\n' "${!ENV_NAME}")"
    return
  fi

  if [ "$INPUT_VALUE" == "$DEFAULT_INPUT_VALUE" ]; then
    warn "Setting value from default value"
    eval "$ENV_NAME"="$INPUT_VALUE"
    return
  fi
}

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

## Create a new Postgresql database
# Parameters:
# 1 - POSTGRESQL_USER
# 2 - POSTGRESQL_PASSWORD
# 3 - DATABASE_NAME
# 4 - POSTGRESQL_POD_NAMESPACE
createDatabase(){
  local PG_USER="$1" PG_PASSWORD="$2" \
        DATABASE_NAME="$3" NAMESPACE="$4"

  local PG_HOST="postgres-postgresql"

  if $VKPR_KUBECTL get pod -n "$NAMESPACE" | grep -q pgpool; then
    PG_HOST="postgres-postgresql-pgpool"
  fi

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
  local PG_USER="$1" PG_PASSWORD="$2" \
        DATABASE_NAME="$3" NAMESPACE="$4"

  local PG_HOST="postgres-postgresql"

  if $VKPR_KUBECTL get pod -n "$NAMESPACE" | grep -q "pgpool"; then
    PG_HOST="postgres-postgresql-pgpool"
  fi

  $VKPR_KUBECTL run check-db --rm -it --restart='Never' --namespace "$NAMESPACE" \
    --image docker.io/bitnami/postgresql-repmgr:11.14.0-debian-10-r12 \
    --env="PGUSER=$PG_USER" --env="PGPASSWORD=$PG_PASSWORD" --env="PGHOST=${PG_HOST}" --env="PGPORT=5432" --env="PGDATABASE=postgres" \
    --command -- psql -lqt | cut -d \| -f 1 | grep "$DATABASE_NAME" | sed -e 's/^[ \t]*//'
}

## Register new repository when url does not exists in helm
# Parameters:
# 1 - REPO_NAME
# 2 - REPO_URL
registerHelmRepository(){
  local REPO_NAME="$1" \
        REPO_URL="$2"
  echo "Adding repository $REPO_NAME"
  $VKPR_HELM repo add "$REPO_NAME" "$REPO_URL" --force-update
}

## Merge KV from the helmArgs key by the VKPR values into application values
# Parameters:
# 1 - APP_NAME
# 2 - APP_VALUES
mergeVkprValuesHelmArgs() {
  local APP_NAME="$1" APP_VALUES="$2"

  [[ ! -f "$VKPR_FILE" ]] && return

  if [[ $($VKPR_YQ eval ".${APP_NAME} | has (\"helmArgs\")" "$CURRENT_PWD"/vkpr.yaml) == true ]]; then
    cp "$CURRENT_PWD"/vkpr.yaml "$(dirname "$0")"/vkpr-cp.yaml

    # foreach key in helmargs, merge the values into application value
    for i in $($VKPR_YQ eval ".${APP_NAME}.helmArgs | keys" "$CURRENT_PWD"/vkpr.yaml | cut -d " " -f2); do
      $VKPR_YQ eval-all -i \
        ". * {\"${i}\": select(fileIndex==1).${APP_NAME}.helmArgs.${i}} | select(fileIndex==0)" \
        "$APP_VALUES" "$(dirname "$0")"/vkpr-cp.yaml
    done
    rm "$(dirname "$0")"/vkpr-cp.yaml

  fi
}

mergeVkprValuesExtraArgs() {
  local APP_NAME="$1" APP_VALUES="$2"

  [[ ! -f "$VKPR_FILE" ]] && return

  if [[ $($VKPR_YQ eval ".${APP_NAME} | has (\"extraArgs\")" "$CURRENT_PWD"/vkpr.yaml) == true ]]; then
    cp "$CURRENT_PWD"/vkpr.yaml "$(dirname "$0")"/vkpr-cp.yaml

    # foreach key in extraArgs, merge the values into application value
    for i in $($VKPR_YQ eval ".${APP_NAME}.extraArgs | keys" "$CURRENT_PWD"/vkpr.yaml | cut -d " " -f2); do
      $VKPR_YQ eval-all -i \
        ". * {\"${i}\": select(fileIndex==1).${APP_NAME}.extraArgs.${i}} | select(fileIndex==0)" \
        "$APP_VALUES" "$(dirname "$0")"/vkpr-cp.yaml
    done
    rm "$(dirname "$0")"/vkpr-cp.yaml

  fi
}

## Encode text
# Parameters:
# 1 - STRING
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
