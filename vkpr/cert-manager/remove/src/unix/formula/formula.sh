#!/bin/sh

runFormula() {
  VKPR_HOME=~/.vkpr
  echoColor "yellow" "Removing cert-manager (CRDs will *NOT* be deleted)..."
  #$VKPR_HOME/bin/kubectl delete crd $($VKPR_HOME/bin/kubectl get crd -o name | grep cert | cut -d"/" -f2)
  #rm -rf $VKPR_HOME/configs/cert-manager/ $VKPR_HOME/values/cert-manager/
  $VKPR_HOME/bin/helm uninstall cert-manager -n cert-manager
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
