#!/bin/sh

runFormula() {
  local VKPR_CERT_VERSION="v1.5.3"

  installCRDS
  addCertManager
  installCertManager
  addTokenDNS
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
  local VKPR_ENV_CERT_ISSUER="$ISSUER"
  $VKPR_YQ eval $VKPR_CERT_MANAGER_VALUES \
  | $VKPR_HELM upgrade -i -f - \
      --namespace cert-manager --create-namespace \
      --set ingressShim.defaultIssuerName="$VKPR_ENV_CERT_ISSUER" \
      --version "$VKPR_CERT_VERSION" \
      --wait --timeout 5m \
      vkpr-cert-manager jetstack/cert-manager
}


addTokenDNS() {
  local VKPR_CERT_TOKEN=$(dirname "$0")/utils/token-dns.yaml
  local BASE64_ARGS=""  # detect OS for proper base64 args
  if [[ "$OSTYPE" != "darwin"* ]]; then
    BASE64_ARGS="-w0"
  fi
  if [ -z "$DO_TOKEN" ]; then
    echo "red" "No token available, skipping digitalocean-dns secret deployment."
  else
    echoColor "yellow" "Adding the Token..."
    local VKPR_INPUT_ACCESS_TOKEN_BASE64=$(echo "$DO_TOKEN" | base64 $BASE64_ARGS) \
    $VKPR_YQ eval '.data.access-token = strenv(VKPR_INPUT_ACCESS_TOKEN_BASE64) | .data.access-token style = "double"' "$VKPR_CERT_TOKEN" \
    | $VKPR_KUBECTL apply -f -
  fi
}

installIssuer() {
  echoColor "yellow" "Installing Issuers and/or ClusterIssuers..."
  local VKPR_ISSUER_VALUES=$(dirname "$0")/utils/issuers.yaml
  local VKPR_ENV_CERT_EMAIL="$EMAIL"
  $VKPR_YQ eval '.spec.acme.email = "'$VKPR_ENV_INPUT_EMAIL'"' "$VKPR_ISSUER_VALUES" \
  | $VKPR_KUBECTL apply -f -
}