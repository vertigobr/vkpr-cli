#!/bin/sh

runFormula() {
  local INGRESS_CONTROLLER="nginx"

  local VKPR_ISSUER_VALUES=$(dirname "$0")/utils/issuers_dns01.yaml
  local VKPR_CERT_MANAGER_VALUES=$(dirname "$0")/utils/cert-manager.yaml
  local VKPR_CERT_TOKEN=$(dirname "$0")/utils/token-dns.yaml
  local VKPR_ENV_CERT_ISSUER="$ISSUER"

  checkGlobalConfig $EMAIL "default@vkpr.com" "cert-manager.email" "EMAIL"
  checkGlobalConfig $ISSUER_SOLVER "HTTP01" "cert-manager.solver" "ISSUER_SOLVER"
  checkGlobalConfig $INGRESS_CONTROLLER "nginx" "cert-manager.ingress" "HTTP01_INGRESS"

  startInfos
  installCRDS
  addCertManager
  installCertManager
  installIssuer
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Cert-manager Install Routine")"
  echoColor "bold" "$(echoColor "blue" "Provider:") digitalocean"
  echoColor "bold" "$(echoColor "blue" "Email:") ${VKPR_ENV_EMAIL}"
  echo "=============================="
}

installCRDS() {
  echoColor "yellow" "Installing cert-manager CRDS beforehand..."
  $VKPR_KUBECTL apply -f "https://github.com/jetstack/cert-manager/releases/download/$VKPR_CERT_VERSION/cert-manager.crds.yaml"
}

addCertManager() {
  registerHelmRepository jetstack https://charts.jetstack.io 
}

installCertManager() {
  echoColor "bold" "$(echoColor "green" "Installing cert-manager...")"
  local YQ_VALUES='.ingressShim.defaultIssuerName = "'$VKPR_ENV_CERT_ISSUER'"'
  settingCertmanager
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_CERT_MANAGER_VALUES" \
  | $VKPR_HELM upgrade -i -f - \
      -n cert-manager --create-namespace \
      --version "$VKPR_CERT_VERSION" \
      --wait \
      cert-manager jetstack/cert-manager
}

installIssuer() {
  echoColor "bold" "$(echoColor "green" "Installing Issuers and/or ClusterIssuers...")"
  YQ_VALUES='.spec.acme.email = "'$VKPR_ENV_EMAIL'"'
  case $VKPR_ENV_ISSUER_SOLVER in
    DNS01)
        addTokenDNS
      ;;
    HTTP01)
        VKPR_ISSUER_VALUES=$(dirname "$0")/utils/issuers_http01.yaml
        YQ_VALUES=''$YQ_VALUES' |
          .spec.acme.solvers[0].http01.ingress.class = "'$VKPR_ENV_HTTP01_INGRESS'"
        '
      ;;
  esac
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_ISSUER_VALUES" \
  | $VKPR_KUBECTL apply -f -
}

addTokenDNS() {
  local BASE64_ARGS=""  # detect OS for proper base64 args
  if [[ "$OSTYPE" != "darwin"* ]]; then
    BASE64_ARGS="-w0"
  fi
  if [ -z "$DO_TOKEN" ]; then
    echo "red" "No token available, skipping digitalocean-dns secret deployment."
  else
    echoColor "yellow" "Adding the Token..."
    local VKPR_INPUT_ACCESS_TOKEN_BASE64=$(echo "$DO_TOKEN" | base64 $BASE64_ARGS) 
    $VKPR_YQ eval '.data.access-token = strenv(VKPR_INPUT_ACCESS_TOKEN_BASE64) | .data.access-token style = "double"' "$VKPR_CERT_TOKEN" \
    | $VKPR_KUBECTL apply -f -
  fi
}

settingCertmanager() {
  mergeVkprValuesHelmArgs "cert-manager" $VKPR_INGRESS_VALUES
}