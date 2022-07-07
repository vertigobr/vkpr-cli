#!/bin/bash

runFormula() {
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "keycloak.namespace" "KEYCLOAK_NAMESPACE"

  if [[ $(checkPodName "$VKPR_ENV_KEYCLOAK_NAMESPACE" "keycloak-0") != "true" ]]; then
    error "Error, Keycloak doesn't up or installed yet"
    exit
  fi

  info "Importing Realm..."
  $VKPR_KUBECTL cp "$REALM_PATH" keycloak-0:tmp/realm.json  -n "$VKPR_ENV_KEYCLOAK_NAMESPACE"
  $VKPR_KUBECTL exec -it keycloak-0 -n "$VKPR_ENV_KEYCLOAK_NAMESPACE" -- sh -c "
    kcadm.sh config credentials --server http://localhost:8080/auth --realm master \
      --user $KEYCLOAK_USERNAME --password $KEYCLOAK_PASSWORD --config /tmp/kcadm.config && \
    kcadm.sh create realms -f /tmp/realm.json --config /tmp/kcadm.config && \
    rm -f /tmp/kcadm.config /tmp/realm.json
  "
}
