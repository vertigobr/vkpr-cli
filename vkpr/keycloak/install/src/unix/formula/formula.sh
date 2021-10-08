#!/bin/sh

runFormula() {
  local PG_USER="postgres"
  local PG_PASSWORD=$($VKPR_JQ -r '.credential.password' ~/.rit/credentials/default/postgres)
  local PG_DATABASE_NAME="keycloak"
  local INGRESS_CONTROLLER="nginx"
  local VKPR_KEYCLOAK_IMPORT="$(dirname "$0")/utils/realm.json"
  local VKPR_KEYCLOAK_VALUES=$(dirname "$0")/utils/keycloak.yaml

  checkGlobalConfig $DOMAIN "localhost" "domain" "DOMAIN"
  checkGlobalConfig $SECURE "false" "secure" "SECURE"
  checkGlobalConfig $INGRESS_CONTROLLER "nginx" "keycloak.ingressClassName" "KEYCLOAK_INGRESS"
  checkGlobalConfig $ADMIN_USER "admin" "keycloak.admin_user" "KEYCLOAK_ADMIN_USER"
  checkGlobalConfig $ADMIN_PASSWORD "vkpr123" "keycloak.admin_password" "KEYCLOAK_ADMIN_PASSWORD"
  checkGlobal "keycloak.resources" $VKPR_KEYCLOAK_VALUES "resources"
  checkGlobal "keycloak.extraEnv" $VKPR_KEYCLOAK_VALUES

  local VKPR_ENV_KEYCLOAK_DOMAIN="keycloak.${VKPR_ENV_DOMAIN}"

  startInfos
  addRepoKeycloak
  createRealmSecret
  installKeycloak
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Keycloak Install Routine")"
  echoColor "bold" "$(echoColor "blue" "Keycloak Admin Username:") ${VKPR_ENV_KEYCLOAK_ADMIN_USER}"
  echoColor "bold" "$(echoColor "blue" "Keycloak Admin Password:") ${VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD}"
  echoColor "bold" "$(echoColor "blue" "Keycloak Domain:") ${VKPR_ENV_KEYCLOAK_DOMAIN}"
  echoColor "bold" "$(echoColor "blue" "Ingress Controller:") ${VKPR_ENV_KEYCLOAK_INGRESS}"
  echo "=============================="
}

addRepoKeycloak(){
  registerHelmRepository bitnami https://charts.bitnami.com/bitnami
}

createRealmSecret(){
  $VKPR_KUBECTL create ns $VKPR_K8S_NAMESPACE 2> /dev/null
  $VKPR_KUBECTL create secret generic keycloak-realm-secret --namespace $VKPR_K8S_NAMESPACE --from-file=$VKPR_KEYCLOAK_IMPORT 2> /dev/null
}

installKeycloak(){
  local YQ_VALUES=""
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
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_KEYCLOAK_VALUES" \
  | $VKPR_HELM upgrade -i --version "$VKPR_KEYCLOAK_VERSION" \
    --create-namespace -n $VKPR_K8S_NAMESPACE \
    --wait --timeout 10m -f - keycloak bitnami/keycloak
}

settingKeycloak(){
  local DB_EXIST=$1
  YQ_VALUES='.ingress.hostname = "'$VKPR_ENV_KEYCLOAK_DOMAIN'" |
    .ingress.ingressClassName = "'$VKPR_ENV_KEYCLOAK_INGRESS'" |
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
      .externalDatabase.host = "postgres-postgresql" |
      .externalDatabase.port = "5432" |
      .externalDatabase.user = "'$PG_USER'" |
      .externalDatabase.password = "'$PG_PASSWORD'" |
      .externalDatabase.database = "'$PG_DATABASE_NAME'"
    '
  fi
  if [[ $(checkPodName "prometheus-prometheus-stack-kube-prom-prometheus") == "true" ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .metrics.enabled = true |
      .metrics.serviceMonitor.enabled = true |
      .metrics.serviceMonitor.namespace = "vkpr" |
      .metrics.serviceMonitor.interval = "30s"
    '
  fi
}