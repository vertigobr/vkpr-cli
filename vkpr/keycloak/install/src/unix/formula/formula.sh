#!/bin/sh

runFormula() {
  local PG_USER="postgres"
  local PG_PASSWORD=$($VKPR_JQ -r '.credential.password' ~/.rit/credentials/default/postgres)
  local PG_DATABASE_NAME="keycloak"
  local VKPR_ENV_KEYCLOAK_DOMAIN="vkpr-keycloak.${VKPR_ENV_DOMAIN}"
  local VKPR_KEYCLOAK_IMPORT="$(dirname "$0")/utils/realm.json"
  local VKPR_KEYCLOAK_VALUES=$(dirname "$0")/utils/keycloak.yaml

  checkGlobalConfig $DOMAIN "localhost" "domain" "DOMAIN"
  checkGlobalConfig $SECURE "false" "secure" "SECURE"
  checkGlobalConfig $ADMIN_USER "admin" "keycloak.admin_user" "KEYCLOAK_ADMIN_USER"
  checkGlobalConfig $ADMIN_PASSWORD "vkpr123" "keycloak.admin_password" "KEYCLOAK_ADMIN_PASSWORD"
  checkGlobal "keycloak.resources" $VKPR_KEYCLOAK_VALUES"resources"
  checkGlobal "keycloak.extraEnv" $VKPR_KEYCLOAK_VALUES

  addRepoKeycloak
  $VKPR_KUBECTL create ns $VKPR_K8S_NAMESPACE
  $VKPR_KUBECTL create secret generic vkpr-realm-secret --namespace $VKPR_K8S_NAMESPACE --from-file=$VKPR_KEYCLOAK_IMPORT
  installKeycloak
}

addRepoKeycloak(){
  registerHelmRepository bitnami https://charts.bitnami.com/bitnami
}

installKeycloak(){
  if [[ $(checkPodName "postgres-postgresql") = "true" ]]; then
    echoColor "green" "Initializing Keycloak with Postgres already created"
    local PG_EXISTING_DATABASE=$(checkExistingDatabase $PG_USER $PG_PASSWORD $PG_DATABASE_NAME $PG_DATABASE_NAME)
    if [[ $PG_EXISTING_DATABASE != "keycloak" ]]; then
      echoColor "green" "Creating Database Instance..."
      createDatabase $PG_USER $PG_PASSWORD $PG_DATABASE_NAME
    fi
    settingKeycloak true
  else
    echoColor "yellow" "There is no Postgres installed, Keycloak will generate one for your use"
    settingKeycloak false
  fi
  local YQ_VALUES=""
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_KEYCLOAK_VALUES" \
  | $VKPR_HELM upgrade -i --version "$VKPR_KEYCLOAK_VERSION" \
    --create-namespace -n $VKPR_K8S_NAMESPACE \
    --wait --timeout 10m -f - keycloak bitnami/keycloak
}

settingKeycloak(){
  local DB_EXIST=$1
  YQ_VALUES='.ingress.hostname = "'$VKPR_ENV_KEYCLOAK_DOMAIN'" |
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
}