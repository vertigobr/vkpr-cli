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
  checkGlobalConfig $HA "false" "keycloak.HA" "HA"
  checkGlobalConfig $INGRESS_CONTROLLER "nginx" "keycloak.ingressClassName" "KEYCLOAK_INGRESS"
  checkGlobalConfig $ADMIN_USER "admin" "keycloak.admin_user" "KEYCLOAK_ADMIN_USER"
  checkGlobalConfig $ADMIN_PASSWORD "vkpr123" "keycloak.admin_password" "KEYCLOAK_ADMIN_PASSWORD"
  checkGlobal "keycloak.resources" $VKPR_KEYCLOAK_VALUES "resources"
  checkGlobal "keycloak.helmArgs" $VKPR_KEYCLOAK_VALUES

  local VKPR_ENV_KEYCLOAK_DOMAIN="keycloak.${VKPR_ENV_DOMAIN}"

  startInfos
  addRepoKeycloak
  installKeycloak
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Keycloak Install Routine")"
  echoColor "bold" "$(echoColor "blue" "HTTPS:") ${VKPR_ENV_SECURE}"
  echoColor "bold" "$(echoColor "blue" "HA:") ${VKPR_ENV_HA}"
  echoColor "bold" "$(echoColor "blue" "Keycloak Admin Username:") ${VKPR_ENV_KEYCLOAK_ADMIN_USER}"
  echoColor "bold" "$(echoColor "blue" "Keycloak Admin Password:") ${VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD}"
  echoColor "bold" "$(echoColor "blue" "Keycloak Domain:") ${VKPR_ENV_KEYCLOAK_DOMAIN}"
  echoColor "bold" "$(echoColor "blue" "Ingress Controller:") ${VKPR_ENV_KEYCLOAK_INGRESS}"
  echo "=============================="
}

addRepoKeycloak(){
  registerHelmRepository bitnami https://charts.bitnami.com/bitnami
}

installKeycloak(){
  local YQ_VALUES=".postgresql.enabled = false"
  configureKeycloakDB
  settingKeycloak
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_KEYCLOAK_VALUES" \
  | $VKPR_HELM upgrade -i --version "$VKPR_KEYCLOAK_VERSION" \
    --create-namespace -n $VKPR_K8S_NAMESPACE \
    --wait --timeout 10m -f - keycloak bitnami/keycloak
}

settingKeycloak(){
  YQ_VALUES=''$YQ_VALUES' |
    .ingress.hostname = "'$VKPR_ENV_KEYCLOAK_DOMAIN'" |
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
  if [[ $VKPR_ENV_HA = true ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .replicaCount = 3 |
      .serviceDiscovery.enabled = "true" |
      .serviceDiscovery.protocol = "dns.DNS_PING" |
      .serviceDiscovery.properties[0] = "dns_query=\"keycloak-headless.vkpr.svc.cluster.local\"" |
      .proxyAddressForward = "false" |
      .cache.ownersCount = 3 |
      .cache.authOwnersCount = 3
    '
  fi
  # todo: Metrics to keycloak
  if [[ $VKPR_ENV_METRICS == "true" ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .metrics.enabled = true |
      .metrics.serviceMonitor.enabled = true |
      .metrics.serviceMonitor.namespace = "vkpr" |
      .metrics.serviceMonitor.interval = "30s"
    '
  fi
}

configureKeycloakDB(){
  local PG_HA="false"
  [[ $VKPR_ENV_HA = true ]] && PG_HA="true"
  if [[ $(checkPodName "postgres-postgresql") != "true" ]]; then
    echoColor "green" "Initializing postgresql to Keycloak"
    rit vkpr postgres install --HA=$PG_HA --default
  fi
  if [[ $(checkExistingDatabase $PG_USER $PG_PASSWORD $PG_DATABASE_NAME) != "keycloak" ]]; then
    echoColor "green" "Creating Database Instance..."
    createDatabase $PG_USER $PG_PASSWORD $PG_DATABASE_NAME
  fi

  local PG_HOST="postgres-postgresql"
  [[ ! -z $($VKPR_KUBECTL get pod -n $VKPR_K8S_NAMESPACE | grep pgpool) ]] && PG_HOST="postgres-postgresql-pgpool"
  YQ_VALUES=''$YQ_VALUES' |
    .externalDatabase.host = "'$PG_HOST'" |
    .externalDatabase.port = "5432" |
    .externalDatabase.user = "'$PG_USER'" |
    .externalDatabase.password = "'$PG_PASSWORD'" |
    .externalDatabase.database = "'$PG_DATABASE_NAME'"
  '
}