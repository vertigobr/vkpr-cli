#!/bin/sh

runFormula() {
  VKPR_CERT_VERSION="v1.5.0"

  VKPR_CERT_VALUES=$VKPR_HOME/values/cert-manager.yaml
  VKPR_CERT_ISSUER=$(dirname "$0")/utils/issuers.yaml
  VKPR_CERT_TOKEN=$(dirname "$0")/utils/token-dns.yaml
  VKPR_INPUT_ACCESS_TOKEN=$TOKEN
  VKPR_INPUT_EMAIL="$EMAIL"

  mkdir -p $VKPR_HOME/values/cert-manager/

  install_crds
  add_repo_certmanager
  install_certmanager
  add_token_dns
  add_issuer
}

install_crds() {
  echoColor "yellow" "Installing cert-manager CRDS beforehand..."
  $VKPR_KUBECTL apply -f "https://github.com/jetstack/cert-manager/releases/download/$VKPR_CERT_VERSION/cert-manager.crds.yaml"
}

add_repo_certmanager() {
  $VKPR_HELM repo add jetstack https://charts.jetstack.io
  $VKPR_HELM repo update
}

install_certmanager() {
  echoColor "yellow" "Installing cert-manager..."
  get_cert_values
  # namespace cert-manager mandatory
  $VKPR_HELM upgrade -i -f $VKPR_CERT_VALUES \
    -n cert-manager --create-namespace \
    --version "$VKPR_CERT_VERSION" \
    vkpr-cert-manager jetstack/cert-manager
}

get_cert_values() {
  # checking local values
  if [ ! -f "$VKPR_CERT_VALUES" ]; then
    VKPR_CERT_VALUES=$(dirname "$0")/utils/cert-manager.yaml
    echoColor "yellow" "Reading cert-manager values from formula default file"
  else
    echoColor "green" "Reading cert-manager values from project local file '.vkpr/values/cert-manager.yaml'"
  fi
}

add_token_dns() {
  # detect OS for proper base64 args
  BASE64_ARGS=""
  if [[ "$OSTYPE" != "darwin"* ]]; then
    BASE64_ARGS="-w0"
  fi
  if [ -z "$VKPR_INPUT_ACCESS_TOKEN" ]; then
    echo "red" "No token available, skipping digitalocean-dns secret deployment."
  else
    # replaces token in VKPR_CERT_TOKEN template
    echoColor "yellow" "Adding the Token..."
    VKPR_INPUT_ACCESS_TOKEN_BASE64=$(echo "$VKPR_INPUT_ACCESS_TOKEN" | base64 $BASE64_ARGS) \
    $VKPR_YQ eval '.data.access-token = strenv(VKPR_INPUT_ACCESS_TOKEN_BASE64) | .data.access-token style = "double"' "$VKPR_CERT_TOKEN" \
      | $VKPR_KUBECTL apply -f -
  fi
}

add_issuer() {
  echoColor "yellow" "Installing Issuers and/or ClusterIssuers..."
  $VKPR_YQ eval '.spec.acme.email = strenv(VKPR_INPUT_EMAIL)' "$VKPR_CERT_ISSUER" \
    | $VKPR_KUBECTL apply -f -
}