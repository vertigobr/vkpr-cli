#!/bin/bash

runFormula() {
  echoColor "bold" "$(echoColor "green" "Importing Realm...")"
  $VKPR_KUBECTL cp $REALM_PATH keycloak-0:tmp/realm.json  -n $VKPR_K8S_NAMESPACE
  $VKPR_KUBECTL exec -it keycloak-0 -n $VKPR_K8S_NAMESPACE -- sh -c "
  kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user admin --password $KEYCLOAK_PASSWORD --config /tmp/kcadm.config && \
  kcadm.sh create realms -f /tmp/realm.json --config /tmp/kcadm.config && \
  rm -f /tmp/kcadm.config /tmp/realm.json
  "
}
