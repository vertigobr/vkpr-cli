#!/bin/sh

runFormula() {
  VKPR_HOME=~/.vkpr
  VKPR_HELM=$VKPR_HOME/bin/helm
  VKPR_POSTGRES_VALUES=$(dirname "$0")/utils/postgres.yaml

  addRepoPostgres
  installPostgres

}

addRepoPostgres(){
  $VKPR_HELM repo add bitnami https://charts.bitnami.com/bitnami
  $VKPR_HELM repo update
}

installPostgres(){
  echoColor "yellow" "Installing postgres..."
  $VKPR_HELM upgrade -i --set global.postgresql.postgresqlPassword=$PASSWORD postgres bitnami/postgresql
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
