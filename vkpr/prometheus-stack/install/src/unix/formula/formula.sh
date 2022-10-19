#!/usr/bin/env bash
source "$(dirname "$0")"/unix/formula/commands-operators.sh

runFormula() {
  local VKPR_ENV_GRAFANA_DOMAIN VKPR_ENV_ALERT_MANAGER_DOMAIN VKPR_PROMETHEUS_VALUES HELM_ARGS;
  formulaInputs
  validateInputs

  VKPR_ENV_GRAFANA_DOMAIN="grafana.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_ENV_ALERT_MANAGER_DOMAIN="alertmanager.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_ENV_PROMETHEUS_DOMAIN="prometheus.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_PROMETHEUS_VALUES=$(dirname "$0")/utils/prometheus-stack.yaml

  startInfos
  settingPrometheusStack
  [ $DRY_RUN = false ] && registerHelmRepository prometheus-community https://prometheus-community.github.io/helm-charts
  installApplication "prometheus-stack" "prometheus-community/kube-prometheus-stack" "$VKPR_ENV_PROMETHEUS_STACK_NAMESPACE" "$VKPR_PROMETHEUS_STACK_VERSION" "$VKPR_PROMETHEUS_VALUES" "$HELM_ARGS"
  [ $DRY_RUN = false ] && checkComands
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Prometheus-Stack Install Routine"
  boldNotice "Domain: $VKPR_ENV_GLOBAL_DOMAIN"
  boldNotice "Secure: $VKPR_ENV_GLOBAL_SECURE"
  boldNotice "Ingress Controller: $VKPR_ENV_PROMETHEUS_STACK_INGRESS_CLASS_NAME"
  boldNotice "Grafana password: $VKPR_ENV_GRAFANA_PASSWORD"
  boldNotice "AlertManager enabled: $VKPR_ENV_ALERTMANAGER"
  bold "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "prometheus-stack.ingressClassName" "PROMETHEUS_STACK_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "PROMETHEUS_STACK_NAMESPACE"
  checkGlobalConfig "false" "false" "prometheus-stack.k8sExporters" "PROMETHEUS_STACK_EXPORTERS"
  checkGlobalConfig "${HA-:false}" "false" "prometheus-stack.HA" "PROMETHEUS_STACK_HA"
  ## AlertManager
  checkGlobalConfig "$ALERTMANAGER" "false" "prometheus-stack.alertManager.enabled" "ALERTMANAGER"
  if [[ "$VKPR_ENV_ALERTMANAGER" = true ]]; then
    checkGlobalConfig "false" "false" "prometheus-stack.alertManager.ssl.enabled" "ALERTMANAGER_SSL"
    checkGlobalConfig "" "" "prometheus-stack.alertManager.ssl.crt" "ALERTMANAGER_SSL_CERTIFICATE"
    checkGlobalConfig "" "" "prometheus-stack.alertManager.ssl.key" "ALERTMANAGER_SSL_KEY"
    checkGlobalConfig "" "" "prometheus-stack.alertManager.ssl.secretName" "ALERTMANAGER_SSL_SECRET"
  fi
  ## Grafana
  checkGlobalConfig "$GRAFANA_PASSWORD" "vkpr123" "prometheus-stack.grafana.adminPassword" "GRAFANA_PASSWORD"
  checkGlobalConfig "false" "false" "prometheus-stack.grafana.persistence" "GRAFANA_PERSISTENCE"
  checkGlobalConfig "$SSL" "false" "prometheus-stack.grafana.ssl.enabled" "GRAFANA_SSL"
  if [[ "$VKPR_ENV_GRAFANA_SSL" = true ]]; then
    checkGlobalConfig "$CRT_FILE" "" "prometheus-stack.grafana.ssl.crt" "GRAFANA_SSL_CERTIFICATE"
    checkGlobalConfig "$KEY_FILE" "" "prometheus-stack.grafana.ssl.key" "GRAFANA_SSL_KEY"
    checkGlobalConfig "" "" "prometheus-stack.grafana.ssl.secretName" "GRAFANA_SSL_SECRET"
  fi
  ## Prometheus
  checkGlobalConfig "false" "false" "prometheus-stack.prometheus.enabled" "PROMETHEUS"
  checkGlobalConfig "false" "false" "prometheus-stack.prometheus.persistence" "PROMETHEUS_PERSISTENCE"
  if [[ "$VKPR_ENV_PROMETHEUS" = true ]]; then
    checkGlobalConfig "false" "false" "prometheus-stack.prometheus.ssl.enabled" "PROMETHEUS_SSL"
    checkGlobalConfig "" "" "prometheus-stack.prometheus.ssl.crt" "PROMETHEUS_SSL_CERTIFICATE"
    checkGlobalConfig "" "" "prometheus-stack.prometheus.ssl.key" "PROMETHEUS_SSL_KEY"
    checkGlobalConfig "" "" "prometheus-stack.prometheus.ssl.secretName" "PROMETHEUS_SSL_SECRET"
  fi

  # Integrate
  checkGlobalConfig "false" "false" "prometheus-stack.grafana.openid.enabled" "GRAFANA_KEYCLOAK_OPENID"
  checkGlobalConfig "" "" "prometheus-stack.grafana.openid.clientSecret" "GRAFANA_KEYCLOAK_OPENID_CLIENTSECRET"

  # External app values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "loki.namespace" "LOKI_NAMESPACE"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "keycloak.namespace" "KEYCLOAK_NAMESPACE"
}

validateInputs() {
  # App values
  validatePrometheusDomain "$VKPR_ENV_GLOBAL_DOMAIN"
  validatePrometheusSecure "$VKPR_ENV_GLOBAL_SECURE"
  validatePrometheusIngressClassName "$VKPR_ENV_PROMETHEUS_STACK_INGRESS_CLASS_NAME"
  validatePrometheusNamespace "$VKPR_ENV_PROMETHEUS_STACK_NAMESPACE"
  validatePrometheusHA "$VKPR_ENV_PROMETHEUS_STACK_HA"
  ## AlertManager
  validateAlertManagerEnabled "$VKPR_ENV_ALERTMANAGER"
  if [[ "$VKPR_ENV_ALERTMANAGER" = true ]]; then
    validateAlertManagerSSL "$VKPR_ENV_ALERTMANAGER_SSL"
    if [[ "$VKPR_ENV_ALERTMANAGER_SSL" = true ]]; then
      validateAlertManagerCertificate "$VKPR_ENV_ALERTMANAGER_SSL_CERTIFICATE"
      validateAlertManagerKey "$VKPR_ENV_ALERTMANAGER_SSL_KEY"
      validateAlertManagerSecret "$VKPR_ENV_ALERTMANAGER_SSL_SECRET"
    fi
  fi
  ## Grafana
  validateGrafanaPwd "$VKPR_ENV_GRAFANA_PASSWORD"
  validatePrometheusK8S "$VKPR_ENV_PROMETHEUS_STACK_EXPORTERS"
  validateGrafanaPersistance "$VKPR_ENV_GRAFANA_PERSISTENCE"
  validateGrafanaSSL "$VKPR_ENV_GRAFANA_SSL"
  if [[ "$VKPR_ENV_GRAFANA_SSL" = true ]]; then
    validateGrafanaCertificate "$VKPR_ENV_GRAFANA_SSL_CERTIFICATE"
    validateGrafanaKey "$VKPR_ENV_GRAFANA_SSL_KEY"
    validateGrafanaSecret "$VKPR_ENV_GRAFANA_SSL_SECRET"
  fi
  ## Prometheus
  validatePrometheusEnabled "$VKPR_ENV_PROMETHEUS"
  if [[ "$VKPR_ENV_PROMETHEUS" = true ]]; then
    validatePrometheusSSL "$VKPR_ENV_PROMETHEUS_SSL"
    if [[ "$VKPR_ENV_PROMETHEUS_SSL" = true ]]; then
      validatePrometheusCertificate "$VKPR_ENV_PROMETHEUS_SSL_CERTIFICATE"
      validatePrometheusKey "$VKPR_ENV_PROMETHEUS_SSL_KEY"
      validatePrometheusSecret "$VKPR_ENV_PROMETHEUS_SSL_SECRET"
    fi
  fi
  validatePrometheusPersistance "$VKPR_ENV_PROMETHEUS_PERSISTENCE"
  # External app values
  validateLokiNamespace "$VKPR_ENV_LOKI_NAMESPACE"
}

settingPrometheusStack() {
  settingGrafanaValues
  settingPrometheusValues
  [[ "$VKPR_ENV_ALERTMANAGER" == true ]] && settingAlertManagerValues

  if [[ "$VKPR_ENV_PROMETHEUS_STACK_EXPORTERS" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .kubeApiServer.enabled = true |
      .kubelet.enabled = true |
      .kubeControllerManager.enabled = true |
      .coreDns.enabled = true |
      .kubeDns.enabled = false |
      .kubeEtcd.enabled = true |
      .kubeScheduler.enabled = true |
      .kubeProxy.enabled = true |
      .kubeStateMetrics.enabled = true |
      .nodeExporter.enabled = true
    "
  fi

  if [[ $(checkPodName "$VKPR_ENV_LOKI_NAMESPACE" "loki-stack") == "true" ]]; then
    YQ_VALUES="$YQ_VALUES |
      .grafana.additionalDataSources[0].name = \"Loki\" |
      .grafana.additionalDataSources[0].type = \"loki\" |
      .grafana.additionalDataSources[0].url = \"http://loki-stack.$VKPR_ENV_LOKI_NAMESPACE:3100\" |
      .grafana.additionalDataSources[0].access = \"proxy\" |
      .grafana.additionalDataSources[0].basicAuth = false |
      .grafana.additionalDataSources[0].editable = true
    "
  fi

  if [[ "$VKPR_ENV_PROMETHEUS_STACK_HA" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .alertmanager.alertmanagerSpec.replicas = 3 |
      .alertmanager.alertmanagerSpec.retention = 1d |
      .prometheus.prometheusSpec.replicas = 3 |
      .prometheus.prometheusSpec.retention = 90d
    "
  fi

  settingPrometheusStackEnvironment

  debug "YQ_CONTENT = $YQ_VALUES"
}

settingGrafanaValues() {
  YQ_VALUES=".grafana.ingress.hosts[0] = \"$VKPR_ENV_GRAFANA_DOMAIN\" |
   .grafana.adminPassword = \"$VKPR_ENV_GRAFANA_PASSWORD\" |
   .grafana.ingress.ingressClassName = \"$VKPR_ENV_PROMETHEUS_STACK_INGRESS_CLASS_NAME\"
  "

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .grafana.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .grafana.ingress.tls[0].hosts[0] = \"$VKPR_ENV_GRAFANA_DOMAIN\" |
      .grafana.ingress.tls[0].secretName = \"grafana-cert\"
    "
  fi

  if [[ "$VKPR_ENV_GRAFANA_SSL" == "true" ]]; then
    if [[ "$VKPR_ENV_GRAFANA_SSL_SECRET" == "" ]]; then
      VKPR_ENV_GRAFANA_SSL_SECRET="grafana-certificate"
      $VKPR_KUBECTL create secret tls $VKPR_ENV_GRAFANA_SSL_SECRET -n "$VKPR_ENV_GRAFANA_NAMESPACE" \
        --cert="$VKPR_ENV_GRAFANA_SSL_CERTIFICATE" \
        --key="$VKPR_ENV_GRAFANA_SSL_KEY"
    fi
    YQ_VALUES="$YQ_VALUES |
      .grafana.ingress.tls[0].hosts[0] = \"$VKPR_ENV_GRAFANA_DOMAIN\" |
      .grafana.ingress.tls[0].secretName = \"$VKPR_ENV_GRAFANA_SSL_SECRET\"
     "
  fi

  if [[ "$VKPR_ENV_GRAFANA_PERSISTENCE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .grafana.persistence.enabled = true |
      .grafana.persistence.size = \"8Gi\"
    "
  fi

  if [[ $VKPR_ENV_GRAFANA_KEYCLOAK_OPENID == "true" ]] && [[ ! -z $VKPR_ENV_GRAFANA_KEYCLOAK_OPENID_CLIENTSECRET ]]; then
    if [[ $VKPR_ENV_GLOBAL_DOMAIN == "localhost" ]]; then
      KEYCLOAK_ADDRESS="http://keycloak.localhost:8000"
      GRAFANA_ADDRESS="grafana.localhost:8000"
    else
      KEYCLOAK_ADDRESS="https://keycloak.${VKPR_ENV_GLOBAL_DOMAIN}"
      GRAFANA_ADDRESS="grafana.${VKPR_ENV_GLOBAL_DOMAIN}"
      GRAFANA_HTTPS="https"
    fi

    YQ_VALUES="$YQ_VALUES |
      .grafana.env.GF_SERVER_ROOT_URL = \"${GRAFANA_HTTPS:-http}://${GRAFANA_ADDRESS}/\" |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_ENABLED = true |
      .grafana.env.GF_AUTH_DISABLE_LOGIN_FORM = false |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_ALLOW_SIGN_UP = true |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_AUTO_LOGIN = false |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_TLS_SKIP_VERIFY_INSECURE = true |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_NAME = \"Keycloak\" |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_CLIENT_ID = \"grafana\" |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET = \"$VKPR_ENV_GRAFANA_KEYCLOAK_OPENID_CLIENTSECRET\" |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_SCOPES = \"openid profile email\" |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_ROLE_ATTRIBUTE_PATH = \"contains(roles[], 'admin') && 'Admin' || contains(roles[], 'editor') && 'Editor' || 'Viewer'\" |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_AUTH_URL = \"${KEYCLOAK_ADDRESS}/realms/grafana/protocol/openid-connect/auth\" |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_TOKEN_URL = \"http://keycloak.${VKPR_ENV_KEYCLOAK_NAMESPACE}:80/realms/grafana/protocol/openid-connect/token\" |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_API_URL = \"http://keycloak.${VKPR_ENV_KEYCLOAK_NAMESPACE}:80/realms/grafana/protocol/openid-connect/userinfo\" |
      .grafana.env.GF_AUTH_SIGNOUT_REDIRECT_URL = \"${KEYCLOAK_ADDRESS}/realms/grafana/protocol/openid-connect/logout?redirect_uri=${GRAFANA_HTTPS:-http}%3A%2F%2F${GRAFANA_ADDRESS}%2Flogin\"
    "
  fi
}

settingPrometheusValues() {
  YQ_VALUES="$YQ_VALUES |
    .prometheus.enabled = true |
    .prometheus.ingress.enabled = true |
    .prometheus.ingress.hosts[0] = \"$VKPR_ENV_PROMETHEUS_DOMAIN\" |
    .prometheus.ingress.ingressClassName = \"$VKPR_ENV_PROMETHEUS_STACK_INGRESS_CLASS_NAME\"
  "

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .prometheus.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .prometheus.ingress.tls[0].hosts[0] = \"$VKPR_ENV_PROMETHEUS_DOMAIN\" |
      .prometheus.ingress.tls[0].secretName = \"prometheus-cert\"
    "
  fi

  if [[ "$VKPR_ENV_PROMETHEUS_SSL" == "true" ]]; then
    if [[ "$VKPR_ENV_PROMETHEUS_SSL_SECRET" == "" ]]; then
      VKPR_ENV_PROMETHEUS_SSL_SECRET="prometheus-certificate"
      $VKPR_KUBECTL create secret tls $VKPR_ENV_PROMETHEUS_SSL_SECRET -n "$VKPR_ENV_PROMETHEUS_NAMESPACE" \
        --cert="$VKPR_ENV_PROMETHEUS_SSL_CERTIFICATE" \
        --key="$VKPR_ENV_PROMETHEUS_SSL_KEY"
    fi
    YQ_VALUES="$YQ_VALUES |
      .prometheus.ingress.tls[0].hosts[0] = \"$VKPR_ENV_PROMETHEUS_DOMAIN\" |
      .prometheus.ingress.tls[0].secretName = \"$VKPR_ENV_PROMETHEUS_SSL_SECRET\"
     "
  fi

  if [[ "$VKPR_ENV_PROMETHEUS_PERSISTENCE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0] = \"ReadWriteOnce\" |
      .prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage = \"8Gi\"
    "
  fi
}

settingAlertManagerValues() {
  YQ_VALUES="$YQ_VALUES |
    .alertmanager.enabled = true |
    .alertmanager.ingress.enabled = true |
    .alertmanager.ingress.hosts[0] = \"$VKPR_ENV_ALERT_MANAGER_DOMAIN\" |
    .alertmanager.ingress.ingressClassName = \"$VKPR_ENV_PROMETHEUS_STACK_INGRESS_CLASS_NAME\"
  "

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .alertmanager.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .alertmanager.ingress.tls[0].hosts[0] = \"$VKPR_ENV_ALERT_MANAGER_DOMAIN\" |
      .alertmanager.ingress.tls[0].secretName = \"alertmanager-cert\"
    "
  fi

  if [[ "$VKPR_ENV_ALERTMANAGER_SSL" == "true" ]]; then
    if [[ "$VKPR_ENV_ALERTMANAGER_SSL_SECRET" == "" ]]; then
      VKPR_ENV_ALERTMANAGER_SSL_SECRET="alertmanager-certificate"
      $VKPR_KUBECTL create secret tls $VKPR_ENV_ALERTMANAGER_SSL_SECRET -n "$VKPR_ENV_ALERTMANAGER_NAMESPACE" \
        --cert="$VKPR_ENV_ALERTMANAGER_SSL_CERTIFICATE" \
        --key="$VKPR_ENV_ALERTMANAGER_SSL_KEY"
    fi
    YQ_VALUES="$YQ_VALUES |
      .alertmanager.ingress.tls[0].hosts[0] = \"$VKPR_ENV_ALERT_MANAGER_DOMAIN\" |
      .alertmanager.ingress.tls[0].secretName = \"$VKPR_ENV_ALERTMANAGER_SSL_SECRET\"
     "
  fi

}

settingPrometheusStackEnvironment() {
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    # YQ_VALUES="$YQ_VALUES"
  fi
}

checkComands (){
  COMANDS_EXISTS=$($VKPR_YQ eval ".prometheus-stack | has(\"commands\")" "$VKPR_FILE" 2> /dev/null)
  debug "$COMANDS_EXISTS"
  if [ "$COMANDS_EXISTS" == true ]; then
    bold "=============================="
    boldInfo "Checking additional prometheus-stack commands..."
    if [ $($VKPR_YQ eval ".prometheus-stack.commands | has(\"import\")" "$VKPR_FILE") == true ]; then
      checkGlobalConfig "" "" "prometheus-stack.commands.import" "DASHBOARD_PATH"
      validatePrometheusImportDashboardPath "$VKPR_ENV_DASHBOARD_PATH"
      importDashboard "$VKPR_ENV_DASHBOARD_PATH" "$VKPR_ENV_PROMETHEUS_STACK_NAMESPACE"
    fi
  fi
}