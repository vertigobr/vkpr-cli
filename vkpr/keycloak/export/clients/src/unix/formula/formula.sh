#!/bin/bash

runFormula() {
  bold "$(info "Exporting Realm Clients ID from $REALM_NAME...")"

  # Global values
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "global.namespace" "GLOBAL_NAMESPACE"
  
  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "keycloak.namespace" "NAMESPACE"

  $VKPR_KUBECTL exec -it keycloak-0 -n "$VKPR_ENV_NAMESPACE" -- sh -c "
  kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user $KEYCLOAK_USERNAME --password $KEYCLOAK_PASSWORD --config /tmp/kcadm.config && \
  kcadm.sh get clients -r $REALM_NAME --config /tmp/kcadm.config > /tmp/${REALM_NAME}-clientsid.json && \
  rm -f /tmp/kcadm.config
  "
  $VKPR_KUBECTL cp keycloak-0:tmp/"${REALM_NAME}"-clientsid.json clientsid.json -n "$VKPR_ENV_NAMESPACE"
  # shellcheck disable=SC2016
  echo "{}" | $VKPR_JQ --argjson groupInfo "$(<clientsid.json)" '.clients += $groupInfo' > "${REALM_NAME}"-clientsid.json
  rm clientsid.json
  $VKPR_KUBECTL exec -it keycloak-0 -n "$VKPR_ENV_NAMESPACE" -- sh -c "rm -f /tmp/${REALM_NAME}-clientsid.json"
}
