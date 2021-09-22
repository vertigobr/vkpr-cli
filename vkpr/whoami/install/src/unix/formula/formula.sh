#!/bin/sh

runFormula() {
  checkGlobalConfig $DOMAIN "localhost" "domain" "DOMAIN"
  checkGlobalConfig $SECURE "false" "secure" "SECURE"
  
  local VKPR_ENV_WHOAMI_DOMAIN="whoami.${VKPR_ENV_DOMAIN}"

  echo $VKPR_ENV_WHOAMI_DOMAIN
  addRepoWhoami
  installWhoami
}

addRepoWhoami(){
  $VKPR_HELM repo add cowboysysop https://cowboysysop.github.io/charts/ --force-update
}

installWhoami(){
  echoColor "yellow" "Installing whoami..."
  local VKPR_WHOAMI_VALUES=$(dirname "$0")/utils/whoami.yaml
  local YQ_VALUES='.ingress.hosts[0].host = "'$VKPR_ENV_WHOAMI_DOMAIN'"'
  if [[ $VKPR_ENV_SECURE == true ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .ingress.annotations.["'kubernetes.io/tls-acme'"] = "'true'" |
      .ingress.tls[0].hosts[0] = "'$VKPR_ENV_WHOAMI_DOMAIN'" |
      .ingress.tls[0].secretName = "'whoami-cert'"
    '
  fi
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_WHOAMI_VALUES" \
  | $VKPR_HELM upgrade -i -f - vkpr-whoami cowboysysop/whoami
}