#!/bin/sh

runFormula() {
  PG_USER="postgres"
  PG_PASSWORD=$($VKPR_JQ -r '.credential.password' ~/.rit/credentials/default/postgres)
  PG_DATABASE_NAME="keycloak"
  VKPR_KEYCLOAK_YAML=$(dirname "$0")/utils/keycloak.yaml

  checkGlobalConfig $DOMAIN "keycloak.localhost" "keycloak.domain" "KEYCLOAK_DOMAIN"
  checkGlobalConfig $SECURE "false" "keycloak.secure" "KEYCLOAK_SECURE" # Unused Variable TODO: See if is secure and then enable the cert-manager and TLS
  checkGlobalConfig $ADMIN_USER "admin" "keycloak.admin_user" "KEYCLOAK_ADMIN_USER"
  checkGlobalConfig $ADMIN_PASSWORD "vkpr123" "keycloak.admin_password" "KEYCLOAK_ADMIN_PASSWORD"

  addRepoKeycloak
  installKeycloak
}

addRepoKeycloak(){
  $VKPR_HELM repo add bitnami https://charts.bitnami.com/bitnami
  $VKPR_HELM repo update
}

verifyExistingPostgres(){
  EXISTING_POSTGRES=$($VKPR_KUBECTL get po/postgres-postgresql-0 -o name --ignore-not-found | cut -d "/" -f2)
  if [[ $EXISTING_POSTGRES = "postgres-postgresql-0" ]]; then
    POSTGRES=$($VKPR_KUBECTL wait --for=condition=Ready po/postgres-postgresql-0 -o name | cut -d "/" -f2)
    if [[ $POSTGRES = "postgres-postgresql-0" ]]; then
      echo "true"
      return
    fi
  fi
  echo "false"
}

settingKeycloak(){
  $VKPR_YQ eval '.ingress.hosts[0].host = "'$VKPR_ENV_KEYCLOAK_DOMAIN'" | .ingress.tls[0].hosts[0] = "'$VKPR_ENV_KEYCLOAK_DOMAIN'" |
  .auth.adminUser = "'$VKPR_ENV_KEYCLOAK_ADMIN_USER'" |
  .auth.adminPassword = "'$VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD'"' "$VKPR_KEYCLOAK_YAML" \
 | $VKPR_HELM upgrade -i -f - keycloak bitnami/keycloak
}

settingKeycloakDB(){
  $VKPR_YQ eval '.ingress.hosts[0].host = "'$VKPR_ENV_KEYCLOAK_DOMAIN'" | .ingress.tls[0].hosts[0] = "'$VKPR_ENV_KEYCLOAK_DOMAIN'" |
  .externalDatabase.host = "postgres-postgresql" | .externalDatabase.port = "5432" |
  .externalDatabase.user = "'$PG_USER'" | .externalDatabase.password = "'$PG_PASSWORD'" |
  .externalDatabase.database = "'$PG_DATABASE_NAME'" |
  .auth.adminUser = "'$VKPR_ENV_KEYCLOAK_ADMIN_USER'" | .auth.adminPassword = "'$VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD'"' "$VKPR_KEYCLOAK_YAML" \
 | $VKPR_HELM upgrade -i -f - keycloak bitnami/keycloak
}

installKeycloak(){
  if [[ $(verifyExistingPostgres) = "true" ]]; then
    echoColor "yellow" "Initializing Keycloak with Postgres already created"
    VKPR_KEYCLOAK_YAML=$(dirname "$0")/utils/keycloak-db.yaml
    PG_EXISTING_DATABASE=$(checkExistingDatabase $PG_USER $PG_PASSWORD $PG_DATABASE_NAME $PG_DATABASE_NAME)
    if [[ ! -n $PG_EXISTING_DATABASE ]]; then
      createDatabase $PG_USER $PG_PASSWORD $PG_DATABASE_NAME
    fi
    settingKeycloakDB
  else
    echoColor "yellow" "There is no Postgres installed, Keycloak will generate one for your use"
    settingKeycloak
  fi
}