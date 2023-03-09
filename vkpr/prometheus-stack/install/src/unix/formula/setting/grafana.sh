#!/usr/bin/env bash

settingGrafanaValues() {
  YQ_VALUES=".grafana.ingress.hosts[0] = \"$VKPR_ENV_GRAFANA_DOMAIN\" |
   .grafana.adminPassword = \"$VKPR_ENV_GRAFANA_PASSWORD\" |
   .grafana.ingress.ingressClassName = \"$VKPR_ENV_PROMETHEUS_STACK_INGRESS_CLASS_NAME\"
  "

  YQ_VALUES="$YQ_VALUES |
   .grafana.sidecar.datasources.uid = \"prometheus\" |
   .grafana.sidecar.datasources.url = \"http://prometheus-stack-kube-prom-prometheus.$VKPR_ENV_PROMETHEUS_STACK_NAMESPACE:9090\" 
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
      createSslSecret "$VKPR_ENV_GRAFANA_SSL_SECRET" "$VKPR_ENV_PROMETHEUS_STACK_NAMESPACE" "$VKPR_ENV_GRAFANA_SSL_CERTIFICATE" "$VKPR_ENV_GRAFANA_SSL_KEY"
    fi
    YQ_VALUES="$YQ_VALUES |
      .grafana.ingress.tls[0].hosts[0] = \"$VKPR_ENV_GRAFANA_DOMAIN\" |
      .grafana.ingress.tls[0].secretName = \"$VKPR_ENV_GRAFANA_SSL_SECRET\"
     "
  fi

  if [[ "$VKPR_ENV_GRAFANA_PERSISTENCE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .grafana.persistence.enabled = true |
      .grafana.persistence.size = \"$VKPR_ENV_GRAFANA_VOLUME_SIZE\"
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
