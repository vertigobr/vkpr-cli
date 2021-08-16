#!/bin/sh

runFormula() {
  VKPR_HOME=~/.vkpr
  VKPR_HELM=$VKPR_HOME/bin/helm
  VKPR_WHOAMI_VALUES=$(dirname "$0")/utils/whoami.yaml

  addRepoWhoami
  installWhoami
}

addRepoWhoami(){
  $VKPR_HELM repo add cowboysysop https://cowboysysop.github.io/charts/
  $VKPR_HELM repo update
}

installWhoami(){
  echoColor "yellow" "Installing whoami..."
  $VKPR_HOME/bin/yq eval '.ingress.hosts[0].host = "'$DOMAIN'" | .ingress.tls[0].hosts[0] = "'$DOMAIN'"' "$VKPR_WHOAMI_VALUES" \
 | $VKPR_HELM upgrade -i -f - whoami cowboysysop/whoami
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