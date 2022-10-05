#!/usr/bin/env bash

addKongDependencies(){
  mkdir -p /tmp/config/

  local COOKIE_DOMAIN_MANAGER="manager.$VKPR_ENV_GLOBAL_DOMAIN" COOKIE_DOMAIN_PORTAL="portal.$VKPR_ENV_GLOBAL_DOMAIN"\
    COOKIE_SECURE="$VKPR_ENV_GLOBAL_SECURE" COOKIE_SAMESITE="Lax"

  if [[ $VKPR_ENVIRONMENT == "okteto" ]]; then
    COOKIE_DOMAIN_MANAGER="cloud.okteto.net"
    COOKIE_DOMAIN_PORTAL="cloud.okteto.net"
    COOKIE_SECURE="true"
    COOKIE_SAMESITE="Strict"
  fi

  createCookieConf "admin_gui_session" $COOKIE_DOMAIN_MANAGER "$COOKIE_SECURE" "$COOKIE_SAMESITE" "${VKPR_ENV_KONG_KEYCLOAK_OPENID_CLIENTSECRET:-$(openssl rand -base64 32)}"
  createCookieConf "portal_session" $COOKIE_DOMAIN_PORTAL "$COOKIE_SECURE" "$COOKIE_SAMESITE" "${VKPR_ENV_KONG_KEYCLOAK_OPENID_CLIENTSECRET:-$(openssl rand -base64 32)}"

  if [[ $VKPR_ENV_KONG_KEYCLOAK_OPENID == "true" ]]; then
    createAdminAuthConf
  fi

  if [[ "$VKPR_ENV_KONG_MODE" == "hybrid" ]] && [[ "$VKPR_ENV_KONG_PLANE" == "control" ]]; then
    openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
                -keyout $VKPR_HOME/certs/cluster.key -out $VKPR_HOME/certs/cluster.crt \
                -days 1095 -subj "/CN=kong_clustering" 
  fi
}

createCookieConf() {
  local NAME="$1" DOMAIN="$2" \
  SECURE="$3" SAMESITE="$4" \
  SECRET="$5"

  printf "{
  \"storage\": \"kong\",
  \"secret\": \"%s\",
  \"cookie_name\": \"%s\",
  \"cookie_domain\": \"%s\",
  \"cookie_secure\": %s,
  \"cookie_samesite\": \"%s\"
}" "$SECRET" "$NAME" "$DOMAIN" "$SECURE" "$SAMESITE" > /tmp/config/"$NAME"_conf
}

createAdminAuthConf() {
  $VKPR_YQ eval -i -o json ".issuer = \"https://keycloak.$VKPR_ENV_GLOBAL_DOMAIN/realms/kong/.well-known/openid-configuration/\" |
    .end_session_endpoint = \"https://keycloak.$VKPR_ENV_GLOBAL_DOMAIN/realms/kong/protocol/openid-connect/logout\" |
    .logout_redirect_uri[0] = \"https://keycloak.$VKPR_ENV_GLOBAL_DOMAIN/realms/kong/protocol/openid-connect/logout\" |
    .redirect_uri[0] = \"https://manager.$VKPR_ENV_GLOBAL_DOMAIN\" |
    .client_id[0] = \"kong-manager\" |
    .client_secret[0] = \"$VKPR_ENV_KONG_KEYCLOAK_OPENID_CLIENTSECRET\"" "$(dirname "$0")"/utils/admin_gui_auth_conf
}

addKongDependencies
