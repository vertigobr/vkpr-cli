#!/bin/sh

runFormula() {
  echoColor "yellow" "Instalando external-dns..."
  VKPR_HOME=~/.vkpr
  VKPR_EXTERNAL_DNS_LOCAL=$VKPR_HOME/values/external-dns
  VKPR_EXTERNAL_DNS_VALUES=$VKPR_EXTERNAL_DNS_LOCAL/external-dns.yaml
  mkdir -p $VKPR_EXTERNAL_DNS_LOCAL
  VKPR_EXTERNAL_DNS_VALUES=$(dirname "$0")/utils/external-dns.yaml

  getProvider $PROVIDER
  add_repo_external_dns
  install_external_dns
}

add_repo_external_dns() {
  $VKPR_HOME/bin/helm repo add bitnami https://charts.bitnami.com/bitnami
  $VKPR_HOME/bin/helm repo update
}

install_external_dns() {
  $VKPR_HOME/bin/helm upgrade -i vkpr -f $VKPR_EXTERNAL_DNS_VALUES bitnami/external-dns
}

get_credentials() {
  # CREDENTIAL INPUT NOT WORKING IN SHELL FORMULA
  # PARSING FILE DIRECTLY AND IGNORING INPUT ("-r" is important!!!)
  #VKPR_ACCESS_TOKEN_INPUT=$(jq -r .credential.token ~/.rit/credentials/default/digitalocean)
  if [ -z "$TOKEN" ]; then
    echo "yellow" "No digitalocean token found in rit credentials. Falling back to DO_AUTH_TOKEN env variable."
    TOKEN="$DO_AUTH_TOKEN"
  fi
  if [ -z "$TOKEN" ]; then
    echoColor "red" "No digitalocean token found in both rit credentials or DO_AUTH_TOKEN env variable."
    echoColor "red" "Cert-manager will fail to negotiate certificates unless you provide the digitalocean-dns secret manually."
    echoColor "red" "Please check https://cert-manager.io/docs/configuration/acme/dns01/digitalocean/"
  fi
}

getProvider(){
  case $1 in
  DIGITALOCEAN)
    get_credentials
    ;;
  AWS)
    echoColor "yellow" "AWS is a working in progress."
    exit 0
    ;;
  esac
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
