#!/bin/bash

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

  createCookieConf "admin_gui_session" $COOKIE_DOMAIN_MANAGER "$COOKIE_SECURE" "$COOKIE_SAMESITE"
  createCookieConf "portal_session" $COOKIE_DOMAIN_PORTAL "$COOKIE_SECURE" "$COOKIE_SAMESITE"

  if [[ "$VKPR_ENV_KONG_MODE" == "hybrid" ]] && [[ "$KONG_PLANE" == "control" ]]; then
    openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
                -keyout $CURRENT_PWD/cluster.key -out $CURRENT_PWD/cluster.crt \
                -days 1095 -subj "/CN=kong_clustering"
  fi
}

createCookieConf() {
  local NAME="$1" DOMAIN="$2" \
  SECURE="$3" SAMESITE="$4"

  printf "{
  \"storage\": \"kong\",
  \"secret\": \"$(openssl rand -base64 32)\",
  \"cookie_name\": \"%s\",
  \"cookie_domain\": \"%s\",
  \"cookie_secure\": %s,
  \"cookie_samesite\": \"%s\"
}" "$NAME" "$DOMAIN" "$SECURE" "$SAMESITE"  > /tmp/config/"$NAME"_conf
}