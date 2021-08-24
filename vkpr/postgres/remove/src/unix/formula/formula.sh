#!/bin/sh

runFormula() {
  VKPR_HOME=~/.vkpr
  VKPR_HELM=$VKPR_HOME/bin/helm

  removePostgres
  removePVC

}

removePostgres(){
  echoColor "green" "Removing Postgres..."
  $VKPR_HELM uninstall postgres
}

removePVC(){
    echoColor "green" "Removing PVC..."
    kubectl delete pvc -l app.kubernetes.io/instance=postgres
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
