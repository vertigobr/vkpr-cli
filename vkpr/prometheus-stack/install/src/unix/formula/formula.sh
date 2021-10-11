#!/bin/sh

runFormula() {
  local VKPR_PROMETHEUS_VALUES=$(dirname "$0")/utils/prometheus.yaml
  local INGRESS_CONTROLLER="nginx"

  checkGlobalConfig $DOMAIN "localhost" "domain" "DOMAIN"
  checkGlobalConfig $SECURE "false" "secure" "SECURE"
  checkGlobalConfig $ALERTMANAGER "false" "prometheus-stack.alertmanager" "PROMETHEUS_ALERT_MANAGER"
  checkGlobalConfig $INGRESS_CONTROLLER "nginx" "prometheus-stack.ingressClassName" "PROMETHEUS_INGRESS"
  
  local VKPR_ENV_GRAFANA_DOMAIN="grafana.${VKPR_ENV_DOMAIN}"
  local VKPR_ENV_ALERT_MANAGER_DOMAIN="alertmanager.${VKPR_ENV_DOMAIN}"

  addRepoPrometheusStack
  installPrometheusStack
}

addRepoPrometheusStack() {
  registerHelmRepository prometheus-community https://prometheus-community.github.io/helm-charts
}

installPrometheusStack() {
  echoColor "yellow" "Installing prometheus stack..."
  local YQ_VALUES='.grafana.ingress.hosts[0] = "'$VKPR_ENV_GRAFANA_DOMAIN'" | .grafana.adminPassword = "'$GRAFANA_PASSWORD'"'
  settingStack
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_PROMETHEUS_VALUES" \
  | $VKPR_HELM upgrade -i --wait --version "$VKPR_PROMETHEUS_STACK_VERSION" \
    --create-namespace --namespace $VKPR_K8S_NAMESPACE \
    -f - prometheus-stack prometheus-community/kube-prometheus-stack
}

settingStack() {
  if [[ $VKPR_ENV_PROMETHEUS_ALERT_MANAGER = true ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .alertmanager.enabled = true |
      .alertmanager.ingress.enabled = true |
      .alertmanager.ingress.hosts[0] = "'$VKPR_ENV_ALERT_MANAGER_DOMAIN'"
    '
  fi
  if [[ $VKPR_ENV_PROMETHEUS_INGRESS != "nginx" ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .alertmanager.ingress.ingressClassName = "traefik" |
      .grafana.ingress.ingressClassName = "traefik"
    ' 
  fi
  if [[ $(checkExistingLoki) = "true" ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .grafana.additionalDataSources[0].name = "Loki" |
      .grafana.additionalDataSources[0].type = "loki" |
      .grafana.additionalDataSources[0].url = "http://loki-stack:3100" |
      .grafana.additionalDataSources[0].access = "proxy" |
      .grafana.additionalDataSources[0].basicAuth = false |
      .grafana.additionalDataSources[0].editable = true
    '
  fi
  if [[ $(checkExistingKeycloak) = "true" ]]; then
    # addapt to use https (only find http)
    local K3D_PORTS=":$($VKPR_K3D cluster ls vkpr-local -o yaml | $VKPR_YQ eval '.[].cluster.nodes[0].portMappings.80/tcp[0].hostport' -)"
    local KEYCLOAK_DOMAIN="vkpr-keycloak.$($VKPR_YQ eval .global.domain $VKPR_GLOBAL)${K3D_PORTS}/auth/realms/grafana/protocol/openid-connect"
    local ROLES="contains(roles[], 'admin') && 'Admin' || contains(roles[], 'editor') && 'Editor' || 'Viewer'"
    YQ_VALUES=''$YQ_VALUES' |
      .grafana.env.GF_SERVER_ROOT_URL = "http://'${VKPR_ENV_GRAFANA_DOMAIN}${K3D_PORTS}'/" |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_ENABLED = true |
      .grafana.env.GF_AUTH_DISABLE_LOGIN_FORM = true |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_NAME = "Keycloak" |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_CLIENT_ID = "grafana" |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET = "3162d962-c3d1-498e-8cb3-a1ae0005c4d9" |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_SCOPES = "openid profile email" |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_ALLOW_SIGN_UP = true |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_AUTO_LOGIN = false |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_TLS_SKIP_VERIFY_INSECURE = true |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_ROLE_ATTRIBUTE_PATH = "'${ROLES}'" |
      .grafana.env.GF_SERVER_ROOT_URL = "http://'${VKPR_ENV_GRAFANA_DOMAIN}'/" |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_AUTH_URL = "http://'${KEYCLOAK_DOMAIN}'/auth" |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_TOKEN_URL = "http://'${KEYCLOAK_DOMAIN}'/token" |
      .grafana.env.GF_AUTH_GENERIC_OAUTH_API_URL = "http://'${KEYCLOAK_DOMAIN}'/usernfo" |
      .grafana.env.GF_AUTH_SIGNOUT_REDIRECT_URL = "http://'${KEYCLOAK_DOMAIN}'/logout?redirect_uri=http%3A%2F%2F'${VKPR_ENV_GRAFANA_DOMAIN}${K3D_PORTS}'%2Flogin"
    '
  fi
  if [[ $VKPR_ENV_SECURE = true ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .grafana.ingress.annotations.["'kubernetes.io/tls-acme'"] = "'true'" |
      .grafana.ingress.tls[0].hosts[0] = "'$VKPR_ENV_GRAFANA_DOMAIN'" |
      .grafana.ingress.tls[0].secretName = "'grafana-cert'"
    '
    if [[ $VKPR_ENV_PROMETHEUS_ALERT_MANAGER = true ]]; then
      YQ_VALUES=''$YQ_VALUES' |
        .alertmanager.ingress.annotations.["'kubernetes.io/tls-acme'"] = "'true'" |
        .alertmanager.ingress.tls[0].hosts[0] = "'$VKPR_ENV_ALERT_MANAGER_DOMAIN'" |
        .alertmanager.ingress.tls[0].secretName = "'alertmanager-cert'"
      '
    fi
  fi
}