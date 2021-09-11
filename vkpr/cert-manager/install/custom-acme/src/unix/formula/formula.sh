#!/bin/sh

runFormula() {
  VKPR_CERT_VERSION="v1.5.3"

  VKPR_CERT_VALUES=$VKPR_HOME/values/cert-manager.yaml
  VKPR_CERT_ISSUER=$(dirname "$0")/utils/issuers.yaml
  VKPR_INPUT_EMAIL="$EMAIL"

  mkdir -p $VKPR_HOME/values/cert-manager/

  install_crds
  add_repo_certmanager
  install_certmanager
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
    cert-manager jetstack/cert-manager
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

add_issuer() {
  echoColor "yellow" "Installing Issuers and/or ClusterIssuers..."
  $VKPR_YQ eval '.spec.acme.email = strenv(VKPR_INPUT_EMAIL)' "$VKPR_CERT_ISSUER" \
    | $VKPR_KUBECTL apply -f -
}
