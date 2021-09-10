#!/bin/sh

runFormula() {
  VKPR_WHOAMI_VALUES=$(dirname "$0")/utils/whoami.yaml

  checkGlobalConfig $DOMAIN "whoami.localhost" "whoami.domain" "WHOAMI_DOMAIN"
  checkGlobalConfig $SECURE "false" "whoami.secure" "WHOAMI_SECURE" # Unused Variable TODO: See if is secure and then enable the cert-manager and TLS
  addRepoWhoami
  installWhoami
}

addRepoWhoami(){
  $VKPR_HELM repo add cowboysysop https://cowboysysop.github.io/charts/
  $VKPR_HELM repo update
}

installWhoami(){
  echoColor "yellow" "Installing whoami..."
  $VKPR_YQ eval '.ingress.hosts[0].host = "'$VKPR_ENV_WHOAMI_DOMAIN'" | .ingress.tls[0].hosts[0] = "'$VKPR_ENV_WHOAMI_DOMAIN'"' "$VKPR_WHOAMI_VALUES" \
 | $VKPR_HELM upgrade -i -f - vkpr-whoami cowboysysop/whoami
}