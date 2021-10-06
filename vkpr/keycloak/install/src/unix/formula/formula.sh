#!/bin/sh

runFormula() {
  
  checkGlobalConfig $DOMAIN "localhost" "domain" "DOMAIN"
  checkGlobalConfig $SECURE "false" "secure" "SECURE"
  checkGlobalConfig $ADMIN_USER "admin" "keycloak.admin_user" "KEYCLOAK_ADMIN_USER"
  checkGlobalConfig $ADMIN_PASSWORD "vkpr123" "keycloak.admin_password" "KEYCLOAK_ADMIN_PASSWORD"

  local PG_USER="postgres"
  local PG_PASSWORD=$($VKPR_JQ -r '.credential.password' ~/.rit/credentials/default/postgres)
  local PG_DATABASE_NAME="keycloak"
  local VKPR_ENV_KEYCLOAK_DOMAIN="vkpr-keycloak.${VKPR_ENV_DOMAIN}"
  local VKPR_KEYCLOAK_IMPORT="$(dirname "$0")/utils/realm.json"

  addRepoKeycloak
  $VKPR_KUBECTL create secret generic vkpr-realm-secret --namespace $VKPR_K8S_NAMESPACE --from-file=$VKPR_KEYCLOAK_IMPORT
  installKeycloak
}

addRepoKeycloak(){
  registerHelmRepository bitnami https://charts.bitnami.com/bitnami
}

settingKeycloak(){
  local DB_EXIST=$1
  local YQ_VALUES='.ingress.hostname = "'$VKPR_ENV_KEYCLOAK_DOMAIN'" |
    .auth.adminUser = "'$VKPR_ENV_KEYCLOAK_ADMIN_USER'" |
    .auth.adminPassword = "'$VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD'"
  '
  if [[ $VKPR_ENV_SECURE = true ]]; then
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
  #if [[ $EXISTING_GRAFANA != "vkpr-prometheus-stack-grafana" ]]; then
  #  YQ_VALUES=''$YQ_VALUES' |
  #    .extraVolumes = "" |
  #    .extraVolumeMounts = "" |
  #    .extraEnvVars = "" 
  #  '
  #fi
  
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_KEYCLOAK_VALUES" \
  | $VKPR_HELM upgrade -i -f - keycloak bitnami/keycloak \
    --namespace $VKPR_K8S_NAMESPACE --create-namespace \
    --wait --timeout 5m
}

installKeycloak(){
  local VKPR_KEYCLOAK_VALUES=$(dirname "$0")/utils/keycloak.yaml
  if [[ $(checkExistingPostgres) = "true" ]]; then
    echoColor "yellow" "Initializing Keycloak with Postgres already created"
    local PG_EXISTING_DATABASE=$(checkExistingDatabase $PG_USER $PG_PASSWORD $PG_DATABASE_NAME $PG_DATABASE_NAME)
    if [[ $PG_EXISTING_DATABASE != "keycloak" ]]; then
      echoColor "yellow" "Creating Database Instance..."
      createDatabase $PG_USER $PG_PASSWORD $PG_DATABASE_NAME
    fi
    settingKeycloak true
  else
    echoColor "yellow" "There is no Postgres installed, Keycloak will generate one for your use"
    settingKeycloak false
  fi
}