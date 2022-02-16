#!/bin/bash

runFormula() {
  echoColor "bold" "$(echoColor "green" "Exporting Realm Clients ID from $REALM_NAME...")"

  checkGlobalConfig $VKPR_K8S_NAMESPACE "vkpr" "keycloak.namespace" "NAMESPACE"

  $VKPR_KUBECTL exec -it keycloak-0 -n $VKPR_ENV_NAMESPACE -- sh -c "
  kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user admin --password $KEYCLOAK_PASSWORD --config /tmp/kcadm.config && \
  kcadm.sh get clients -r $REALM_NAME --config /tmp/kcadm.config > /tmp/${REALM_NAME}-clientsid.json && \
  rm -f /tmp/kcadm.config
  "
  $VKPR_KUBECTL cp keycloak-0:tmp/${REALM_NAME}-clientsid.json clientsid.json -n $VKPR_ENV_NAMESPACE
  echo "{}" | $VKPR_JQ --argjson groupInfo "$(<clientsid.json)" '.clients += $groupInfo' > ${REALM_NAME}-clientsid.json
  rm clientsid.json
  $VKPR_KUBECTL exec -it keycloak-0 -n $VKPR_ENV_NAMESPACE -- sh -c "rm -f /tmp/${REALM_NAME}-clientsid.json"
}
