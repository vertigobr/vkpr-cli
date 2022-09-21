#!/usr/bin/env bash

realmExport () {
  local REALM_NAME=$1 \
        KEYCLOAK_NAMESPACE=$2 

  if [[ $(checkPodName "$KEYCLOAK_NAMESPACE" "keycloak-0") != "true" ]]; then
    error "Error, Keycloak doesn't up or installed yet"
    exit
  fi

  info "Exporting Realm..."
  $VKPR_KUBECTL exec keycloak-0 -n $KEYCLOAK_NAMESPACE -- sh -c "/opt/bitnami/keycloak/bin/kc.sh export --realm $REALM_NAME --dir /bitnami/keycloak --users realm_file > /dev/null | true"
  $VKPR_KUBECTL cp keycloak-0:bitnami/keycloak/${REALM_NAME}-realm.json ${REALM_NAME}-realm.json -n $KEYCLOAK_NAMESPACE
  $VKPR_KUBECTL exec keycloak-0 -n $KEYCLOAK_NAMESPACE -- sh -c "rm /bitnami/keycloak/${REALM_NAME}-realm.json"
}

realmImport (){
  local REALM_PATH=$1 \
        KEYCLOAK_NAMESPACE=$2 \
        KEYCLOAK_USERNAME=$3 \
        KEYCLOAK_PASSWORD=$4

  if [[ $(checkPodName "$KEYCLOAK_NAMESPACE" "keycloak-0") != "true" ]]; then
    error "Error, Keycloak doesn't up or installed yet"
    exit
  fi

  info "Importing Realm..."
  $VKPR_KUBECTL cp "$REALM_PATH" keycloak-0:tmp/realm.json  -n "$KEYCLOAK_NAMESPACE"
  sed -i "s/LOGIN_USERNAME/$KEYCLOAK_USERNAME/g ;
    s/LOGIN_PASSWORD/$KEYCLOAK_PASSWORD/g" "$(dirname "$0")"/src/lib/scripts/keycloak/import-realm.sh
  execScriptsOnPod "$(dirname "$0")"/src/lib/scripts/keycloak/import-realm.sh "keycloak-0" "$KEYCLOAK_NAMESPACE"
}

realmIdp() {
  local REALM_NAME=$1 \
        PROVIDER_NAME=$2 \
        KEYCLOAK_NAMESPACE=$3 \
        KEYCLOAK_USERNAME=$4 \
        KEYCLOAK_PASSWORD=$5 \
        CLIENT_ID=$6 \
        CLIENT_SECRET=$7

  if [[ $(checkPodName "$KEYCLOAK_NAMESPACE" "keycloak-0") != "true" ]]; then
    error "Error, Keycloak doesn't up or installed yet"
    exit
  fi

  info "Adding IDP from $PROVIDER_NAME in the $REALM_NAME realm..."
  sed -i "s/LOGIN_USERNAME/$KEYCLOAK_USERNAME/g ;
    s/LOGIN_PASSWORD/$KEYCLOAK_PASSWORD/g ;
    s/REALM_NAME/$REALM_NAME/g ;
    s/PROVIDER_NAME/$PROVIDER_NAME/g ;
    s/CLIENT_ID/$CLIENT_ID/g ;
    s/CLIENT_SECRET/$CLIENT_SECRET/g" "$(dirname "$0")"/src/lib/scripts/keycloak/identity-providers.sh 
  execScriptsOnPod "$(dirname "$0")"/src/lib/scripts/keycloak/identity-providers.sh "keycloak-0" "$KEYCLOAK_NAMESPACE"
}
