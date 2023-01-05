#!/usr/bin/env bash
source "$(dirname "$0")"/unix/formula/commands-operators.sh

runFormula() {
  local VKPR_ENV_KEYCLOAK_DOMAIN VKPR_KEYCLOAK_VALUES PG_USER PG_DATABASE_NAME PG_HA PG_HOST HELM_ARGS;
  formulaInputs
  validateInputs

  VKPR_ENV_KEYCLOAK_DOMAIN="keycloak.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_KEYCLOAK_VALUES=$(dirname "$0")/utils/keycloak.yaml

  startInfos
  if [ $DRY_RUN = false ]; then
    [[ "$VKPR_ENVIRONMENT" != "okteto" ]] && configureKeycloakDB
    registerHelmRepository bitnami https://charts.bitnami.com/bitnami
  fi
  settingKeycloak
  installApplication "keycloak" "bitnami/keycloak" "$VKPR_ENV_KEYCLOAK_NAMESPACE" "$VKPR_KEYCLOAK_VERSION" "$VKPR_KEYCLOAK_VALUES" "$HELM_ARGS"
  #startupScripts
  [ $DRY_RUN = false ] && checkComands
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Keycloak Install Routine"
  boldNotice "Domain: $VKPR_ENV_KEYCLOAK_DOMAIN"
  boldNotice "Secure: $VKPR_ENV_GLOBAL_SECURE"
  boldNotice "Namespace: $VKPR_ENV_KEYCLOAK_NAMESPACE"
  boldNotice "HA: $VKPR_ENV_KEYCLOAK_HA"
  boldNotice "Ingress Controller: $VKPR_ENV_KEYCLOAK_INGRESS_CLASS_NAME"
  boldNotice "Keycloak Admin Username: $VKPR_ENV_KEYCLOAK_ADMIN_USER"
  boldNotice "Keycloak Admin Password: $VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD"
  bold "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "$HA" "false" "keycloak.HA" "KEYCLOAK_HA"
  checkGlobalConfig "$ADMIN_USER" "admin" "keycloak.adminUser" "KEYCLOAK_ADMIN_USER"
  checkGlobalConfig "$ADMIN_PASSWORD" "vkpr123" "keycloak.adminPassword" "KEYCLOAK_ADMIN_PASSWORD"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "keycloak.ingressClassName" "KEYCLOAK_INGRESS_CLASS_NAME"
  checkGlobalConfig "false" "false" "keycloak.metrics" "KEYCLOAK_METRICS"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "keycloak.namespace" "KEYCLOAK_NAMESPACE"
  checkGlobalConfig "$SSL" "false" "keycloak.ssl.enabled" "KEYCLOAK_SSL"
  checkGlobalConfig "$CRT_FILE" "" "keycloak.ssl.crt" "KEYCLOAK_SSL_CERTIFICATE"
  checkGlobalConfig "$KEY_FILE" "" "keycloak.ssl.key" "KEYCLOAK_SSL_KEY"
  checkGlobalConfig "" "" "keycloak.ssl.secretName" "KEYCLOAK_SSL_SECRET"

  # Integrate
  checkGlobalConfig "false" "false" "keycloak.openid.grafana.enabled" "KEYCLOAK_OPENID_GRAFANA"
  checkGlobalConfig "" "" "keycloak.openid.grafana.clientSecret" "KEYCLOAK_OPENID_GRAFANA_CLIENTSECRET"
  checkGlobalConfig "" "" "keycloak.openid.grafana.identityProviders" "KEYCLOAK_OPENID_GRAFANA_IDENTITY_PROVIDERS"

  checkGlobalConfig "false" "false" "keycloak.openid.kong.enabled" "KEYCLOAK_OPENID_KONG"
  checkGlobalConfig "" "" "keycloak.openid.kong.clientSecret" "KEYCLOAK_OPENID_KONG_CLIENTSECRET"
  checkGlobalConfig "" "" "keycloak.openid.kong.identityProviders" "KEYCLOAK_OPENID_KONG_IDENTITY_PROVIDERS"

  # External apps values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "postgresql.namespace" "POSTGRESQL_NAMESPACE"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "GRAFANA_NAMESPACE"
}

validateInputs() {
  validateKeycloakDomain "$DOMAIN"
  validateKeycloakSecure "$SECURE"

  validateKeycloakHa "$VKPR_ENV_KEYCLOAK_HA"
  validateKeycloakAdminUser "$VKPR_ENV_KEYCLOAK_ADMIN_USER"
  validateKeycloakAdminPwd "$VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD"
  validateKeycloakIngresClassName "$VKPR_ENV_KEYCLOAK_INGRESS_CLASS_NAME"

  validateKeycloakNamespace "$VKPR_ENV_KEYCLOAK_NAMESPACE"
  validateKeycloakMetrics "$VKPR_ENV_KEYCLOAK_METRICS"
  validateKeycloakSsl "$VKPR_ENV_KEYCLOAK_SSL"
  if [[ $VKPR_ENV_KEYCLOAK_SSL == true ]]; then
    validateKeycloakCrt "$VKPR_ENV_KEYCLOAK_SSL_CERTIFICATE"
    validateKeycloakKey "$VKPR_ENV_KEYCLOAK_SSL_KEY"
  fi
  validatePostgresqlNamespace "$VKPR_ENV_POSTGRESQL_NAMESPACE"
  validatePrometheusNamespace "$VKPR_ENV_GRAFANA_NAMESPACE"

}

configureKeycloakDB(){
  PG_USER="postgres"
  PG_DATABASE_NAME="keycloak"

  PG_HOST="postgres-postgresql.$VKPR_ENV_POSTGRESQL_NAMESPACE"
  $VKPR_KUBECTL get pod -n "$VKPR_ENV_POSTGRESQL_NAMESPACE" | grep -q pgpool && PG_HOST="postgres-postgresql-pgpool.$VKPR_ENV_POSTGRESQL_NAMESPACE"

  PG_HA="false"
  if [[ $VKPR_ENV_KEYCLOAK_HA == true ]]; then
    PG_HA="true"
    PG_HOST="postgres-pgpool"
  fi

  if [[ $(checkPodName "$VKPR_ENV_POSTGRESQL_NAMESPACE" "postgres-postgresql") != "true" ]]; then
    info "Initializing postgresql to Keycloak"
    [[ -f $CURRENT_PWD/vkpr.yaml ]] && cp "$CURRENT_PWD"/vkpr.yaml "$(dirname "$0")"
    rit vkpr postgresql install --HA="$PG_HA" --default
  fi

  PG_PASSWORD="$($VKPR_JQ -r '.credential.password' $VKPR_CREDENTIAL/postgres)"
  if [[ $(checkExistingDatabase "$PG_USER" "$PG_PASSWORD" "$PG_DATABASE_NAME" "$VKPR_ENV_POSTGRESQL_NAMESPACE") != "keycloak" ]]; then
    info "Creating Database Instance in postgresql..."
    createDatabase "$PG_USER" "$PG_HOST" "$PG_PASSWORD" "$PG_DATABASE_NAME" "$VKPR_ENV_POSTGRESQL_NAMESPACE"
  fi
}

settingKeycloak(){
  ENV_COUNT=1
  YQ_VALUES=".ingress.hostname = \"$VKPR_ENV_KEYCLOAK_DOMAIN\" |
    .ingress.ingressClassName = \"$VKPR_ENV_KEYCLOAK_INGRESS_CLASS_NAME\" |
    .auth.adminUser = \"$VKPR_ENV_KEYCLOAK_ADMIN_USER\" |
    .auth.adminPassword = \"$VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD\" |
    .externalDatabase.host = \"$PG_HOST\" |
    .externalDatabase.port = \"5432\" |
    .externalDatabase.user = \"$PG_USER\" |
    .externalDatabase.password = \"$PG_PASSWORD\" |
    .externalDatabase.database = \"$PG_DATABASE_NAME\"
  "

  if [[ $VKPR_ENV_GLOBAL_SECURE = true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .proxy = \"passthrough\" |
      .tls.enabled = true |
      .tls.autoGenerated = true |
      .extraEnvVars[$ENV_COUNT].name = \"KEYCLOAK_PRODUCTION\" |
      .extraEnvVars[$ENV_COUNT].value = \"true\" |
      .ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .ingress.annotations.[\"cert-manager.io/cluster-issuer\"] = \"certmanager-issuer\" |
      .ingress.tls = true
    "
    ((ENV_COUNT+=1))
  fi

  if [[ $VKPR_ENV_KEYCLOAK_HA = true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .replicaCount = 3 |
      .cache.enabled = true |
      .pdb.create = true |
      .pdb.minAvailable = \"1\" |
      .topologySpreadConstraints[0].maxSkew = 1 |
      .topologySpreadConstraints[0].topologyKey = \"kubernetes.io/hostname\" |
      .topologySpreadConstraints[0].whenUnsatisfiable = \"ScheduleAnyway\" |
      .topologySpreadConstraints[0].labelSelector.matchLabels.[\"app.kubernetes.io/managed-by\"] = \"vkpr\"
    "
  fi

  if [[ $VKPR_ENV_KEYCLOAK_METRICS == "true" ]] && [[ $(checkPodName "$VKPR_ENV_GRAFANA_NAMESPACE" "prometheus-stack-grafana") == "true" ]]; then
    createGrafanaDashboard "$(dirname "$0")/utils/dashboard.json" "$VKPR_ENV_GRAFANA_NAMESPACE"
    $VKPR_KUBECTL apply -f "$(dirname "$0")"/utils/alerts.yaml -n $VKPR_ENV_GRAFANA_NAMESPACE
    YQ_VALUES="$YQ_VALUES |
      .metrics.enabled = true |
      .metrics.serviceMonitor.enabled = true |
      .metrics.serviceMonitor.namespace = \"$VKPR_ENV_KEYCLOAK_NAMESPACE\" |
      .metrics.serviceMonitor.interval = \"30s\" |
      .metrics.serviceMonitor.scrapeTimeout = \"30s\" |
      .metrics.serviceMonitor.labels.release = \"prometheus-stack\" |
      .metrics.serviceMonitor.endpoints[0].path = \"/metrics\" |
      .metrics.serviceMonitor.endpoints[1].path = \"/realms/master/metrics\" |
      .extraEnvVars[$ENV_COUNT].name = \"URI_METRICS_ENABLED\" |
      .extraEnvVars[$ENV_COUNT].value = \"true\" |
      .extraEnvVars[$((ENV_COUNT+1))].name = \"URI_METRICS_DETAILED\" |
      .extraEnvVars[$((ENV_COUNT+1))].value = \"true\"
    "
    ((ENV_COUNT+=1))
  fi

  if [[ "$VKPR_ENV_KEYCLOAK_SSL" == "true" ]]; then
    KEYCLOAK_TLS_KEY=$(cat $VKPR_ENV_KEYCLOAK_SSL_KEY)
    KEYCLOAK_TLS_CERT=$(cat $VKPR_ENV_KEYCLOAK_SSL_CERTIFICATE)
    if [[ "$VKPR_ENV_KEYCLOAK_SSL_SECRET" != "" ]]; then
      KEYCLOAK_TLS_KEY=$($VKPR_KUBECTL get secret $VKPR_ENV_KEYCLOAK_SSL_SECRET -o=jsonpath="{.data.tls\.key}" -n $VKPR_ENV_KEYCLOAK_NAMESPACE | base64 -d)
      KEYCLOAK_TLS_CERT=$($VKPR_KUBECTL get secret $VKPR_ENV_KEYCLOAK_SSL_SECRET -o=jsonpath="{.data.tls\.crt}" -n $VKPR_ENV_KEYCLOAK_NAMESPACE | base64 -d)
    fi
    YQ_VALUES="$YQ_VALUES |
      .ingress.secrets[0].name = \"$VKPR_ENV_KEYCLOAK_DOMAIN-tls\" |
      .ingress.secrets[0].key = \"$KEYCLOAK_TLS_KEY\" |
      .ingress.secrets[0].certificate = \"$KEYCLOAK_TLS_CERT\"
     "
  fi

  settingKeycloakProvider

  debug "YQ_CONTENT = $YQ_VALUES"
}

settingKeycloakProvider() {
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    YQ_VALUES="$YQ_VALUES |
      del(.externalDatabase) |
      .proxy = \"edge\" |
      .postgresql.enabled = true |
      .postgresql.persistence.enabled = true |
      .postgresql.persistence.size = \"1Gi\" |
      .service.annotations.[\"dev.okteto.com/auto-ingress\"] = \"true\"
    "
  fi
}

startupScripts() {
  if [[ $VKPR_ENV_KEYCLOAK_METRICS == "true" ]]; then
    sed -i "s/LOGIN_USERNAME/$VKPR_ENV_KEYCLOAK_ADMIN_USER/g ;
      s/LOGIN_PASSWORD/$VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD/g
    " "$(dirname "$0")"/src/lib/scripts/keycloak/enable-metrics.sh
    execScriptsOnPod "$(dirname "$0")"/src/lib/scripts/keycloak/enable-metrics.sh "keycloak-0" "$VKPR_ENV_KEYCLOAK_NAMESPACE"
  fi

  if [[ $VKPR_ENV_KEYCLOAK_OPENID_GRAFANA == "true" ]]; then
    if [[ $VKPR_ENV_GLOBAL_DOMAIN == "localhost" ]]; then
      GRAFANA_ADDRESS="http\:\/\/grafana.localhost\:8000"
      GRAFANA_ADDRESS_BASE="http\:\/\/grafana.localhost"
    else
      GRAFANA_ADDRESS="https\:\/\/grafana.${VKPR_ENV_GLOBAL_DOMAIN}"
      GRAFANA_ADDRESS_BASE="http\:\/\/grafana.${VKPR_ENV_GLOBAL_DOMAIN}"
    fi

    sed -i "s/LOGIN_USERNAME/$VKPR_ENV_KEYCLOAK_ADMIN_USER/g ;
      s/LOGIN_PASSWORD/$VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD/g ;
      s/TEMPORARY_PASSWORD/$VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD/g ;
      s/CLIENT_SECRET/${VKPR_ENV_KEYCLOAK_OPENID_GRAFANA_CLIENTSECRET:-$(uuidgen)}/g ;
      s/GRAFANA_DOMAIN/$GRAFANA_ADDRESS/g ;
      s/GRAFANA_ADDRESS_BASE/$GRAFANA_ADDRESS_BASE/g" "$(dirname "$0")"/src/lib/scripts/keycloak/grafana-oidc.sh
    execScriptsOnPod "$(dirname "$0")"/src/lib/scripts/keycloak/grafana-oidc.sh "keycloak-0" "$VKPR_ENV_KEYCLOAK_NAMESPACE"

    if [[ $VKPR_ENV_KEYCLOAK_OPENID_GRAFANA_IDENTITY_PROVIDERS != "" ]]; then
      IDP_LENGTH=$(echo $VKPR_ENV_KEYCLOAK_OPENID_GRAFANA_IDENTITY_PROVIDERS | $VKPR_YQ eval '. | length' -)
      ((IDP_LENGTH--))
      for i in $(seq 0 $IDP_LENGTH); do
        IDP_NAME=$(echo $VKPR_ENV_KEYCLOAK_OPENID_GRAFANA_IDENTITY_PROVIDERS | $VKPR_YQ eval ".[$i].name" -)
        IDP_CLIENTID=$(echo $VKPR_ENV_KEYCLOAK_OPENID_GRAFANA_IDENTITY_PROVIDERS | $VKPR_YQ eval ".[$i].clientID" -)
        IDP_CLIENTSECRET=$(echo $VKPR_ENV_KEYCLOAK_OPENID_GRAFANA_IDENTITY_PROVIDERS | $VKPR_YQ eval ".[$i].clientSecret" -)

        sed "s/LOGIN_USERNAME/$VKPR_ENV_KEYCLOAK_ADMIN_USER/g ;
          s/LOGIN_PASSWORD/$VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD/g ;
          s/REALM_NAME/grafana/g ;
          s/PROVIDER_NAME/$IDP_NAME/g ;
          s/CLIENT_ID/$IDP_CLIENTID/g ;
          s/CLIENT_SECRET/$IDP_CLIENTSECRET/g" "$(dirname "$0")"/src/lib/scripts/keycloak/identity-providers.sh > "$(dirname "$0")"/src/lib/scripts/keycloak/identity-providers-$i.sh
        execScriptsOnPod "$(dirname "$0")"/src/lib/scripts/keycloak/identity-providers-$i.sh "keycloak-0" "$VKPR_ENV_KEYCLOAK_NAMESPACE"
      done
    fi
  fi

  if [[ $VKPR_ENV_KEYCLOAK_OPENID_KONG == "true" ]]; then
    KONG_ADDRESS="https\:\/\/manager.${VKPR_ENV_GLOBAL_DOMAIN}"

    sed -i "s/LOGIN_USERNAME/$VKPR_ENV_KEYCLOAK_ADMIN_USER/g ;
      s/LOGIN_PASSWORD/$VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD/g ;
      s/TEMPORARY_PASSWORD/$VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD/g ;
      s/CLIENT_SECRET/${VKPR_ENV_KEYCLOAK_OPENID_KONG_CLIENTSECRET:-$(uuidgen)}/g ;
      s/KONG_DOMAIN/$KONG_ADDRESS/g" "$(dirname "$0")"/src/lib/scripts/keycloak/kong-oidc.sh
    execScriptsOnPod "$(dirname "$0")"/src/lib/scripts/keycloak/kong-oidc.sh "keycloak-0" "$VKPR_ENV_KEYCLOAK_NAMESPACE"

    if [[ $VKPR_ENV_KEYCLOAK_OPENID_KONG_IDENTITY_PROVIDERS != "" ]]; then
      IDP_LENGTH=$(echo $VKPR_ENV_KEYCLOAK_OPENID_KONG_IDENTITY_PROVIDERS | $VKPR_YQ eval '. | length' -)
      ((IDP_LENGTH--))
      for i in $(seq 0 $IDP_LENGTH); do
        IDP_NAME=$(echo $VKPR_ENV_KEYCLOAK_OPENID_KONG_IDENTITY_PROVIDERS | $VKPR_YQ eval ".[$i].name" -)
        IDP_CLIENTID=$(echo $VKPR_ENV_KEYCLOAK_OPENID_KONG_IDENTITY_PROVIDERS | $VKPR_YQ eval ".[$i].clientID" -)
        IDP_CLIENTSECRET=$(echo $VKPR_ENV_KEYCLOAK_OPENID_KONG_IDENTITY_PROVIDERS | $VKPR_YQ eval ".[$i].clientSecret" -)

        sed "s/LOGIN_USERNAME/$VKPR_ENV_KEYCLOAK_ADMIN_USER/g ;
          s/LOGIN_PASSWORD/$VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD/g ;
          s/REALM_NAME/kong/g ;
          s/PROVIDER_NAME/$IDP_NAME/g ;
          s/CLIENT_ID/$IDP_CLIENTID/g ;
          s/CLIENT_SECRET/$IDP_CLIENTSECRET/g" "$(dirname "$0")"/src/lib/scripts/keycloak/identity-providers.sh > "$(dirname "$0")"/src/lib/scripts/keycloak/identity-providers-$i.sh
        execScriptsOnPod "$(dirname "$0")"/src/lib/scripts/keycloak/identity-providers-$i.sh "keycloak-0" "$VKPR_ENV_KEYCLOAK_NAMESPACE"
      done
    fi
  fi
}

checkComands (){
  COMANDS_EXISTS=$($VKPR_YQ eval ".keycloak | has(\"commands\")" "$VKPR_FILE" 2> /dev/null)
  debug "$COMANDS_EXISTS"
  if [ "$COMANDS_EXISTS" == true ]; then
    bold "=============================="
    boldInfo "Checking additional keycloak commands..."

    if [ $($VKPR_YQ eval ".keycloak.commands.realm | has(\"export\")" "$VKPR_FILE") == true ]; then
      checkGlobalConfig "" "" "keycloak.commands.realm.export" "REALM_NAME"
      realmExport "$VKPR_ENV_REALM_NAME" "$VKPR_ENV_KEYCLOAK_NAMESPACE"
    fi
    if [ $($VKPR_YQ eval ".keycloak.commands.realm | has(\"import\")" "$VKPR_FILE") == true ]; then
      checkGlobalConfig "" "" "keycloak.commands.realm.import.path" "REALM_PATH"
      realmImport "$VKPR_ENV_REALM_PATH" "$VKPR_ENV_KEYCLOAK_NAMESPACE" "$VKPR_ENV_KEYCLOAK_ADMIN_USER" "$VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD"
    fi
    if [ $($VKPR_YQ eval ".keycloak.commands.realm | has(\"idp\")" "$VKPR_FILE") == true ]; then
      checkGlobalConfig "" "" "keycloak.commands.realm.idp.provider" "REALM_IDP_PROVIDER"
      checkGlobalConfig "" "" "keycloak.commands.realm.idp.clientId" "REALM_IDP_CLIENT_ID"
      checkGlobalConfig "" "" "keycloak.commands.realm.idp.clientSecret" "REALM_IDP_CLIENT_SECRET"
      checkGlobalConfig "" "" "keycloak.commands.realm.idp.realmeName" "REALM_NAME_IDP"
      realmIdp "$VKPR_ENV_REALM_NAME_IDP" "$VKPR_ENV_REALM_IDP_PROVIDER" "$VKPR_ENV_KEYCLOAK_NAMESPACE" "$VKPR_ENV_KEYCLOAK_ADMIN_USER" "$VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD" "$VKPR_ENV_REALM_IDP_CLIENT_ID" "$VKPR_ENV_REALM_IDP_CLIENT_SECRET"
    fi
  fi
}
