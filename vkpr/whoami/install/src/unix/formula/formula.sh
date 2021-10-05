#!/bin/sh

runFormula() {
  local VKPR_WHOAMI_VALUES=$(dirname "$0")/utils/whoami.yaml
  local INGRESS_CONTROLLER="nginx"

  checkGlobalConfig $DOMAIN "localhost" "domain" "DOMAIN"
  checkGlobalConfig $SECURE "false" "secure" "SECURE"
  checkGlobalConfig $INGRESS_CONTROLLER "nginx" "whoami.ingressClassName" "WHOAMI_INGRESS"
  checkGlobal "whoami.resources" $VKPR_WHOAMI_VALUES "resources"
  checkGlobal "whoami.extraEnv" $VKPR_WHOAMI_VALUES

  local VKPR_ENV_WHOAMI_DOMAIN="whoami.${VKPR_ENV_DOMAIN}"

  startInfos
  addRepoWhoami
  installWhoami
}

addRepoWhoami(){
  registerHelmRepository cowboysysop https://cowboysysop.github.io/charts/
}

settingWhoami() {
  if [[ $VKPR_ENV_SECURE == true ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .ingress.annotations.["'kubernetes.io/tls-acme'"] = "'true'" |
      .ingress.tls[0].hosts[0] = "'$VKPR_ENV_WHOAMI_DOMAIN'" |
      .ingress.tls[0].secretName = "'whoami-cert'"
    '
  fi
  if [[ $VKPR_ENV_WHOAMI_INGRESS != "nginx" ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .ingress.annotations.["'kubernetes.io/ingress.class'"] = "'$VKPR_ENV_WHOAMI_INGRESS'"
    '
  fi
}

installWhoami() {
  echoColor "green" "Installing whoami..."
  local YQ_VALUES='.ingress.hosts[0].host = "'$VKPR_ENV_WHOAMI_DOMAIN'"'
  settingWhoami
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_WHOAMI_VALUES" \
  $VKPR_HELM upgrade -i -f - vkpr-whoami cowboysysop/whoami \
    --namespace $VKPR_K8S_NAMESPACE --create-namespace \
    --wait --timeout 5m
}