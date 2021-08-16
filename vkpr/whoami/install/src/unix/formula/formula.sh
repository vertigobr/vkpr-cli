#!/bin/sh

runFormula() {
  echoColor "yellow" "Instalando Whoami..."
  VKPR_HOME=~/.vkpr
  VKPR_WHOAMI_VALUES=$(dirname "$0")/utils/whoami.yaml
  addRepoWhoami
  installWhoami
}

addRepoWhoami(){
  helm repo add cowboysysop https://cowboysysop.github.io/charts/
}

verifyHasIngress(){
  INGRESS=$($VKPR_HOME/bin/kubectl wait --for=condition=available deploy ingress-nginx-controller -o name | cut -d "/" -f2)
  if [[ ! $INGRESS = "ingress-nginx-controller" ]]; then
    local res=$?
    echo $res
  fi
}

installWhoami(){
  if [[ ! -n $(verifyHasIngress) ]]; then
    $VKPR_HOME/bin/yq eval '.ingress.hosts[0].host = "'$DOMAIN'" | .ingress.tls[0].hosts[0] = "'$DOMAIN'"' "$VKPR_WHOAMI_VALUES" \
  | helm upgrade -i -f - whoami cowboysysop/whoami
  else
    echoColor "red" "Não há ingress instalado, para utilizar o Whoami no localhost deve-se subir o ingress."
    helm upgrade -i whoami cowboysysop/whoami
  fi
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
