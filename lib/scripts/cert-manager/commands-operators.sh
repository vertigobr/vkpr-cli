#!/usr/bin/env bash

createWildcard() {
  local DOMAIN=$1 \
        NAMESPACE=$2 \
        CERT_VALUES=$3

  info "Creating wildcard certificate..."
  if [[ $(checkPodName "cert-manager" "cert-manager") != "true" ]]; then
    error "Cert-manager not installed in this cluster"
    return
  fi

  CERT_NAME=$(echo "$DOMAIN" | cut -d "." -f1)
  $VKPR_YQ eval ".metadata.name = \"wildcard-certificate-$CERT_NAME\" |
    .metadata.labels.[\"app.kubernetes.io/managed-by\"] = \"vkpr\" |
    .spec.dnsNames[0] = \"*.$DOMAIN\" |
    .spec.secretName = \"wildcard-certificate-$CERT_NAME\"" "$CERT_VALUES" | $VKPR_KUBECTL apply -n $NAMESPACE -f -
}
