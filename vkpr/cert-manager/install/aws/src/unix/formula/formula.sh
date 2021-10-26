#!/bin/sh

runFormula() {
  checkGlobalConfig $EMAIL "default@vkpr.com" "cert-manager.email" "EMAIL"

  startInfos
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
      -n cert-manager --create-namespace \
      --set ingressShim.defaultIssuerName="$VKPR_ENV_CERT_ISSUER" \
      --version "$VKPR_CERT_VERSION" \
      --wait \
      cert-manager jetstack/cert-manager
}


addTokenDNS() {
  local VKPR_CERT_TOKEN=$(dirname "$0")/utils/route53-secret.yaml
  local BASE64_ARGS=""  # detect OS for proper base64 args
  if [[ "$OSTYPE" != "darwin"* ]]; then
    BASE64_ARGS="-w0"
  fi
  echoColor "yellow" "Adding the Token..."
  local VKPR_INPUT_SECRET_KEY_BASE64=$(echo "$AWS_SECRET_KEY" | base64 $BASE64_ARGS)
  $VKPR_YQ eval '.data.secret-access-key = strenv(VKPR_INPUT_SECRET_KEY_BASE64) | 
                  .data.secret-access-key style = "double"' "$VKPR_CERT_TOKEN" \
  | $VKPR_KUBECTL apply -f -
}

installIssuer() {
  echoColor "yellow" "Installing Issuers and/or ClusterIssuers..."
  local VKPR_ISSUER_VALUES=$(dirname "$0")/utils/issuers.yaml
  local VKPR_ENV_INPUT_EMAIL="$VKPR_ENV_EMAIL"
  $VKPR_YQ eval '.spec.acme.email = "'$VKPR_ENV_INPUT_EMAIL'" |
                 .spec.acme.solvers[0].dns01.route53.region = "'$AWS_REGION'" |
                 .spec.acme.solvers[0].dns01.route53.accessKeyID = "'$AWS_ACCESS_KEY'" |
                 .spec.acme.solvers[0].dns01.route53.role = "'$AWS_IAM_ROLE_ARN'"' "$VKPR_ISSUER_VALUES" \
  | $VKPR_KUBECTL apply -f -
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Cert-manager Install Routine")"
  echoColor "bold" "$(echoColor "blue" "Provider:") AWS"
  echoColor "bold" "$(echoColor "blue" "Email:") ${VKPR_ENV_EMAIL}"
  echo "=============================="
}
