#!/bin/sh

runFormula() {
  checkGlobalConfig $DOMAIN "localhost" "domain" "DOMAIN"
  checkGlobalConfig $SECURE "false" "secure" "SECURE"
  checkGlobalConfig $ADMIN_USER "admin" "keycloak.admin_user" "KEYCLOAK_ADMIN_USER"
  checkGlobalConfig $ADMIN_PASSWORD "vkpr123" "keycloak.admin_password" "KEYCLOAK_ADMIN_PASSWORD"

  local PG_USER="postgres"
  local PG_PASSWORD=$($VKPR_JQ -r '.credential.password' ~/.rit/credentials/default/postgres)
  local PG_DATABASE_NAME="keycloak"
  local VKPR_ENV_KEYCLOAK_DOMAIN="keycloak.${VKPR_ENV_DOMAIN}"

  addRepoKeycloak
  installKeycloak
}

addRepoKeycloak(){
  $VKPR_HELM repo add bitnami https://charts.bitnami.com/bitnami --force-update
}

verifyExistingPostgres(){
  local EXISTING_POSTGRES=$($VKPR_KUBECTL get pod/vkpr-postgres-postgresql-0 -o name --ignore-not-found | cut -d "/" -f2)
  if [[ $EXISTING_POSTGRES = "vkpr-postgres-postgresql-0" ]]; then
    local POSTGRES=$($VKPR_KUBECTL wait --for=condition=Ready pod/vkpr-postgres-postgresql-0 -o name | cut -d "/" -f2)
    if [[ $POSTGRES = "vkpr-postgres-postgresql-0" ]]; then
      echo "true"
      return
    fi
  fi
  echo "false"
}

settingKeycloak(){
  local DB_EXIST=$1
  local YQ_VALUES='.ingress.hostname = "'$VKPR_ENV_KEYCLOAK_DOMAIN'" |
    .auth.adminUser = "'$VKPR_ENV_KEYCLOAK_ADMIN_USER'" |
    .auth.adminPassword = "'$VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD'"
  '
  if [[ $VKPR_ENV_SECURE == true ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .ingress.certManager = true |
      .ingress.tls = true
    '
  fi
  if [ $DB_EXIST = true ]; then
    YQ_VALUES=''$YQ_VALUES' |
      .postgresql.enabled = false |
      .externalDatabase.host = "vkpr-postgres-postgresql" |
      .externalDatabase.port = "5432" |
      .externalDatabase.user = "'$PG_USER'" |
      .externalDatabase.password = "'$PG_PASSWORD'" |
      .externalDatabase.database = "'$PG_DATABASE_NAME'"
    '
  fi
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_KEYCLOAK_VALUES" \
  | $VKPR_HELM upgrade -i -f - vkpr-keycloak bitnami/keycloak
}

installKeycloak(){
  local VKPR_KEYCLOAK_VALUES=$(dirname "$0")/utils/keycloak.yaml
  if [[ $(verifyExistingPostgres) = "true" ]]; then
    echoColor "yellow" "Initializing Keycloak with Postgres already created"
    local PG_EXISTING_DATABASE=$(checkExistingDatabase $PG_USER $PG_PASSWORD $PG_DATABASE_NAME $PG_DATABASE_NAME)
    if [ $PG_EXISTING_DATABASE != "keycloak" ]; then
      echoColor "yellow" "Creating Database Instance..."
      createDatabase $PG_USER $PG_PASSWORD $PG_DATABASE_NAME
    fi
    settingKeycloak true
  else
    echoColor "yellow" "There is no Postgres installed, Keycloak will generate one for your use"
    settingKeycloak false
  fi
}