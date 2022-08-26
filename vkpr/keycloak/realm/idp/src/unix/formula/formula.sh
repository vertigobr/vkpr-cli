#!/usr/bin/env bash

runFormula() {
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "keycloak.namespace" "KEYCLOAK_NAMESPACE"

  if [[ $(checkPodName "$VKPR_ENV_KEYCLOAK_NAMESPACE" "keycloak-0") != "true" ]]; then
    error "Error, Keycloak doesn't up or installed yet"
    exit
  fi

  info "Adding IDP from $PROVIDER_NAME in the $REALM_NAME realm..."
  sed -i "s/LOGIN_USERNAME/$KEYCLOAK_USERNAME/g ;
    s/LOGIN_PASSWORD/$KEYCLOAK_PASSWORD/g ;
    s/REALM_NAME/$REALM_NAME/g ;
    s/PROVIDER_NAME/$PROVIDER_NAME/g ;
    s/CLIENT_ID/$CLIENTID/g ;
    s/CLIENT_SECRET/$CLIENTSECRET/g" "$(dirname "$0")"/src/lib/scripts/keycloak/identity-providers.sh
  execScriptsOnPod "$(dirname "$0")"/src/lib/scripts/keycloak/identity-providers.sh "keycloak-0" "$VKPR_ENV_KEYCLOAK_NAMESPACE"
}
