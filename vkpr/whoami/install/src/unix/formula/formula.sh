#!/bin/sh

runFormula() {   
  local VKPR_WHOAMI_VALUES=$(dirname "$0")/utils/whoami.yaml

  checkGlobalConfig $DOMAIN "localhost" "domain" "DOMAIN"
  checkGlobalConfig $SECURE "false" "secure" "SECURE"
  checkGlobalConfig "nginx" "nginx" "whoami.ingressClassName" "WHOAMI_INGRESS"

  local VKPR_ENV_WHOAMI_DOMAIN="whoami.${VKPR_ENV_DOMAIN}"

  startInfos
  addRepoWhoami
  installWhoami
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Whoami Install Routine")"
  echoColor "bold" "$(echoColor "blue" "Whoami Domain:") ${VKPR_ENV_WHOAMI_DOMAIN}"
  echoColor "bold" "$(echoColor "blue" "Ingress Controller:") ${VKPR_ENV_WHOAMI_INGRESS}"
  echo "=============================="
}

addRepoWhoami() {
  registerHelmRepository cowboysysop https://cowboysysop.github.io/charts/
}

settingWhoami() {
  YQ_VALUES=''$YQ_VALUES' |
    .ingress.annotations.["'kubernetes.io/ingress.class'"] = "'$VKPR_ENV_WHOAMI_INGRESS'"
  '
  if [[ $VKPR_ENV_SECURE == true ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .ingress.annotations.["'kubernetes.io/tls-acme'"] = "'true'" |
      .ingress.tls[0].hosts[0] = "'$VKPR_ENV_WHOAMI_DOMAIN'" |
      .ingress.tls[0].secretName = "'whoami-cert'"
    '
  fi

  mergeVkprValuesHelmArgs "whoami" $VKPR_WHOAMI_VALUES
}

installWhoami() {
  echoColor "bold" "$(echoColor "green" "Installing whoami...")"
  local YQ_VALUES='.ingress.hosts[0].host = "'$VKPR_ENV_WHOAMI_DOMAIN'"'
  settingWhoami
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_WHOAMI_VALUES" \
  | $VKPR_HELM upgrade -i --version "$VKPR_WHOAMI_VERSION" \
    --create-namespace -n $VKPR_K8S_NAMESPACE \
    --wait -f - whoami cowboysysop/whoami
}