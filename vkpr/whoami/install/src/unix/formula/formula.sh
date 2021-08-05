#!/bin/sh

runFormula() {
  echoColor "yellow" "Instalando Whoami..."
  VKPR_HOME=~/.vkpr
  mkdir -p $VKPR_HOME/values/whoami
  VKPR_WHOAMI_VALUES=$VKPR_HOME/values/whoami/values.yaml

  addRepoWhoami
  if [[ -e $VKPR_WHOAMI_VALUES ]]; then
      installWhoami
    else
      echoColor "red" "Não há ingress instalado, será criado um ingress padrão para uso"
      touch $VKPR_WHOAMI_VALUES
      printf "ingress:\n  enabled: true\n  pathType: Prefix\n  hosts:\n    - paths:\n      - "/whoami"\n  annotations:\n    kubernetes.io/ingress.class: nginx" >> $VKPR_WHOAMI_VALUES
      installWhoami
  fi
}

addRepoWhoami(){
  helm repo add cowboysysop https://cowboysysop.github.io/charts/
}

installWhoami(){
  if [[ -n $1 ]]; then 
    helm upgrade -i $1 -f $VKPR_WHOAMI_VALUES cowboysysop/whoami
  else 
    helm upgrade -i whoami -f $VKPR_WHOAMI_VALUES cowboysysop/whoami
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
