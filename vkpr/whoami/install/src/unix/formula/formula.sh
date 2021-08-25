#!/bin/sh

runFormula() {
  VKPR_WHOAMI_VALUES=$(dirname "$0")/utils/whoami.yaml

  verifyExistingEnv 'SECURE' "${SECURE}" 'DOMAIN' "${DOMAIN}"
  addRepoWhoami
  installWhoami
}

addRepoWhoami(){
  $VKPR_HELM repo add cowboysysop https://cowboysysop.github.io/charts/
  $VKPR_HELM repo update
}

installWhoami(){
  echoColor "yellow" "Installing whoami..."
  $VKPR_YQ eval '.ingress.hosts[0].host = "'$VKPR_ENV_DOMAIN'" | .ingress.tls[0].hosts[0] = "'$VKPR_ENV_DOMAIN'"' "$VKPR_WHOAMI_VALUES" \
 | $VKPR_HELM upgrade -i -f - whoami cowboysysop/whoami
}