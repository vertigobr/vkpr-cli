#!/bin/sh

runFormula() {
  echoColor "yellow" "Instalando external-dns..."
  VKPR_HOME=~/.vkpr
  mkdir -p $VKPR_HOME/values/external-dns
  VKPR_EXTERNAL_DNS_VALUES=$VKPR_HOME/values/external-dns/values.yaml
  export DO_AUTH_TOKEN=$INPUT_DIGITAL_OCEAN
  if [[ ! -e $VKPR_EXTERNAL_DNS_VALUES ]]; then
      cp . "$(dirname "$0")"/unix/formula/values.yaml $VKPR_HOME/values/external-dns
  fi
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm upgrade -i vkpr -f $VKPR_EXTERNAL_DNS_VALUES bitnami/external-dns
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
