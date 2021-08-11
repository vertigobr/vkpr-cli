#!/bin/sh

runFormula() {
  VKPR_HOME=~/.vkpr
  VKPR_CERT_VALUES=$VKPR_HOME/values/cert-manager/cert-manager.yaml
  VKPR_CERT_ISSUER=$VKPR_HOME/configs/cert-manager/cluster-issuer.yaml
  VKPR_CERT_TOKEN=$VKPR_HOME/configs/cert-manager/token-dns.yaml
  mkdir -p $VKPR_HOME/configs/cert-manager/ $VKPR_HOME/values/cert-manager/

  add_token_dns
  install_crds
  add_repo_certmanager
  add_cluster_issuer
  install_certmanager
}

add_repo_certmanager() {
  $VKPR_HOME/bin/helm repo add jetstack https://charts.jetstack.io
  $VKPR_HOME/bin/helm repo update
}

add_token_dns(){
  export VKPR_ACCESS_TOKEN_INPUT=$INPUT_API_AT_CLUSTER_ISSUER
  . $(dirname "$0")/utils/token-dns.sh $VKPR_CERT_TOKEN
  echo $VKPR_ACCESS_TOKEN_INPUT | base64 >> $VKPR_CERT_TOKEN
}

install_crds() {
  echoColor "yellow" "Adicionando CRDS do cert-manager..."
  $VKPR_HOME/bin/kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.4.2/cert-manager.crds.yaml
}

add_cluster_issuer() {
  echoColor "yellow" "Adicionando Cluster Issuer do cert-manager..."
  export VKPR_EMAIL_INPUT=$INPUT_EMAIL_CLUSTER_ISSUER
  $VKPR_HOME/bin/kubectl apply -f $VKPR_CERT_ISSUER
}

install_certmanager() {
  echoColor "yellow" "Instalando o cert-manager..."
  if [[ ! -e $VKPR_CERT_VALUES ]]; then
    echoColor "red" "Não identificado nenhum values para a aplicacão, será utilizado um values padrão"
    . $(dirname $0)/utils/cert-manager.sh $VKPR_CERT_VALUES
  fi
  $VKPR_HOME/bin/helm upgrade -i -f $VKPR_CERT_VALUES cert-manager jetstack/cert-manager
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
