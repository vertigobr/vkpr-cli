#!/bin/sh

runFormula() {
  
  installCRDS
  addCertManager
  installCertManager
  installIssuer
}

installCRDS() {
  echoColor "yellow" "Installing cert-manager CRDS beforehand..."
  $VKPR_KUBECTL apply -f "https://github.com/jetstack/cert-manager/releases/download/$VKPR_CERT_VERSION/cert-manager.crds.yaml"
}

addCertManager() {
  registerHelmRepository jetstack https://charts.jetstack.io
}

installCertManager() {
  echoColor "yellow" "Installing cert-manager..."
  local VKPR_CERT_MANAGER_VALUES=$(dirname "$0")/utils/cert-manager.yaml
  $VKPR_YQ eval $VKPR_CERT_MANAGER_VALUES \
  | $VKPR_HELM upgrade -i -f - \
      -n cert-manager --create-namespace \
      --version "$VKPR_CERT_VERSION" \
      --wait \
      vkpr-cert-manager jetstack/cert-manager
}

installIssuer() {
  echoColor "yellow" "Installing Issuers and/or ClusterIssuers..."
  local VKPR_ISSUER_VALUES=$(dirname "$0")/utils/issuers.yaml
  local VKPR_ENV_CERT_EMAIL="$EMAIL"
  $VKPR_YQ eval '.spec.acme.email = "'$VKPR_ENV_CERT_EMAIL'"' "$VKPR_ISSUER_VALUES" \
  | $VKPR_KUBECTL apply -f -
}
