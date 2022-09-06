#!/usr/bin/env bash

runFormula() {
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "keycloak.namespace" "KEYCLOAK_NAMESPACE"

  if [[ $(checkPodName "$VKPR_ENV_KEYCLOAK_NAMESPACE" "keycloak-0") != "true" ]]; then
    error "Error, Keycloak doesn't up or installed yet"
    exit
  fi

  info "Exporting Realm..."
  $VKPR_KUBECTL exec keycloak-0 -n $VKPR_ENV_KEYCLOAK_NAMESPACE -- sh -c "/opt/bitnami/keycloak/bin/kc.sh export --realm $REALM_NAME --dir /bitnami/keycloak --users realm_file > /dev/null | true"
  $VKPR_KUBECTL cp keycloak-0:bitnami/keycloak/${REALM_NAME}-realm.json ${REALM_NAME}-realm.json -n $VKPR_ENV_KEYCLOAK_NAMESPACE
  $VKPR_KUBECTL exec keycloak-0 -n $VKPR_ENV_KEYCLOAK_NAMESPACE -- sh -c "rm /bitnami/keycloak/${REALM_NAME}-realm.json"
}
