#!/bin/sh

runFormula() {
  VKPR_HOME=~/.vkpr
  VKPR_CERT_VERSION="v1.5.0"

  get_cert_values
  get_credentials
  VKPR_CERT_ISSUER=$(dirname "$0")/utils/issuers.yaml
  VKPR_CERT_TOKEN=$(dirname "$0")/utils/token-dns.yaml
  #mkdir -p $VKPR_HOME/configs/cert-manager/ $VKPR_HOME/values/cert-manager/

  install_crds
  add_repo_certmanager
  install_certmanager
  add_token_dns
  add_issuer
}

get_credentials() {
  # CREDENTIAL INPUT NOT WORKING IN SHELL FORMULA
  # PARSING FILE DIRECTLY AND IGNORING INPUT ("-r" is important!!!)
  #VKPR_ACCESS_TOKEN_INPUT=$(jq -r .credential.token ~/.rit/credentials/default/digitalocean)
  if [ -z "$VKPR_ACCESS_TOKEN_INPUT" ]; then
    echo "yellow" "No digitalocean token found in rit credentials. Falling back to DO_AUTH_TOKEN env variable."
    VKPR_ACCESS_TOKEN_INPUT="$DO_AUTH_TOKEN"
  fi
  if [ -z "$VKPR_ACCESS_TOKEN_INPUT" ]; then
    echoColor "red" "No digitalocean token found in both rit credentials or DO_AUTH_TOKEN env variable."
    echoColor "red" "Cert-manager will fail to negotiate certificates unless you provide the digitalocean-dns secret manually."
    echoColor "red" "Please check https://cert-manager.io/docs/configuration/acme/dns01/digitalocean/"
  fi
}

get_cert_values() {
  # checking local values
  VKPR_CERT_VALUES="$CURRENT_PWD/.vkpr/cert-manager-values.yaml"
  if [ ! -f "$VKPR_CERT_VALUES" ]; then
    VKPR_CERT_VALUES=$(dirname "$0")/utils/cert-manager-values.yaml
    echoColor "yellow" "Reading cert-manager values from formula default file"
  else
    echoColor "green" "Reading cert-manager values from project local file '.vkpr/cert-manager-values.yaml'"
  fi
}

add_repo_certmanager() {
  $VKPR_HOME/bin/helm repo add jetstack https://charts.jetstack.io
  $VKPR_HOME/bin/helm repo update
}

add_token_dns() {
  # detect OS for proper base64 args
  BASE64_ARGS=""
  if [[ "$OSTYPE" != "darwin"* ]]; then
    BASE64_ARGS="-w0"
  fi
  if [ -z "$VKPR_ACCESS_TOKEN_INPUT" ]; then
    echo "red" "No token available, skipping digitalocean-dns secret deployment."
  else
    # replaces token in VKPR_CERT_TOKEN template
    VKPR_ACCESS_TOKEN_INPUT_BASE64=$(echo "$VKPR_ACCESS_TOKEN_INPUT" | base64 $BASE64_ARGS) \
      $VKPR_HOME/bin/yq eval '.data.access-token = env(VKPR_ACCESS_TOKEN_INPUT_BASE64) | .data.access-token style = "double"' "$VKPR_CERT_TOKEN" \
      | $VKPR_HOME/bin/kubectl apply -f -
  fi
}

install_crds() {
  echoColor "yellow" "Installing cert-manager CRDS beforehand..."
  $VKPR_HOME/bin/kubectl apply -f "https://github.com/jetstack/cert-manager/releases/download/$VKPR_CERT_VERSION/cert-manager.crds.yaml"
}

add_issuer() {
  echoColor "yellow" "Installing Issuers and/or ClusterIssuers..."
  VKPR_EMAIL_INPUT="$INPUT_EMAIL_CLUSTER_ISSUER" \
    ~/.vkpr/bin/yq eval '.spec.acme.email = env(VKPR_EMAIL_INPUT)' "$VKPR_CERT_ISSUER" \
    | $VKPR_HOME/bin/kubectl apply -f -
}

install_certmanager() {
  echoColor "yellow" "Installing cert-manager..."
  # if [[ ! -e $VKPR_CERT_VALUES ]]; then
  #   echoColor "red" "Não identificado nenhum values para a aplicacão, será utilizado um values padrão"
  #   . $(dirname $0)/utils/cert-manager.sh $VKPR_CERT_VALUES
  # fi
  # namespace cert-manager mandatory
  $VKPR_HOME/bin/helm upgrade -i -f "$VKPR_CERT_VALUES" \
    --namespace cert-manager --create-namespace \
    --version "$VKPR_CERT_VERSION" \
    cert-manager jetstack/cert-manager
}

echoColor() {
  case $1 in
    red)
      echo "$(printf '\033[31m')$2$(printf '\033[0m')"
      ;;
    green)
      echo "$(printf '\033[32m')$2$(printf '\033[0m')"
      ;;
    yellow)
      echo "$(printf '\033[33m')$2$(printf '\033[0m')"
      ;;
    blue)
      echo "$(printf '\033[34m')$2$(printf '\033[0m')"
      ;;
    cyan)
      echo "$(printf '\033[36m')$2$(printf '\033[0m')"
      ;;
    esac
}
