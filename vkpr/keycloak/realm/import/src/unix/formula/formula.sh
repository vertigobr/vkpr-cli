#!/usr/bin/env bash

runFormula() {
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "keycloak.namespace" "KEYCLOAK_NAMESPACE"

  if [[ $(checkPodName "$VKPR_ENV_KEYCLOAK_NAMESPACE" "keycloak-0") != "true" ]]; then
    error "Error, Keycloak doesn't up or installed yet"
    exit
  fi

  info "Importing Realm..."
  $VKPR_KUBECTL cp "$REALM_PATH" keycloak-0:tmp/realm.json  -n "$VKPR_ENV_KEYCLOAK_NAMESPACE"
  sed -i "s/LOGIN_USERNAME/$KEYCLOAK_USERNAME/g ;
    s/LOGIN_PASSWORD/$KEYCLOAK_PASSWORD/g" "$(dirname "$0")"/src/lib/scripts/keycloak/import-realm.sh
  execScriptsOnPod "$(dirname "$0")"/src/lib/scripts/keycloak/import-realm.sh "keycloak-0" "$VKPR_ENV_KEYCLOAK_NAMESPACE"
}
