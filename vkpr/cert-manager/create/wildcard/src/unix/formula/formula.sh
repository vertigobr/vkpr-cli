#!/usr/bin/env bash

runFormula() {
  checkGlobalConfig "$NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "cert-manager.certNamespace" "CERTIFICATE_NAMESPACE"

  info "Creating wildcard certificate..."
  if [[ $(checkPodName "cert-manager" "cert-manager") != "true" ]]; then
    error "Cert-manager not installed in this cluster"
    return
  fi

  CERT_NAME=$(echo "$DOMAIN" | cut -d "." -f1)
  $VKPR_YQ eval ".metadata.name = \"wildcard-certificate-$CERT_NAME\" |
    .metadata.labels.[\"app.kubernetes.io/managed-by\"] = \"vkpr\" |
    .spec.dnsNames[0] = \"*.$DOMAIN\" |
    .spec.secretName = \"wildcard-certificate-$CERT_NAME\"" $(dirname "$0")/utils/certificate.yaml | $VKPR_KUBECTL apply -n $VKPR_ENV_CERTIFICATE_NAMESPACE -f -
}
