#!/bin/bash

runFormula() {
  local VKPR_CONSUL_VALUES=$(dirname "$0")/utils/consul.yaml
  local INGRESS_CONTROLLER="nginx"

  checkGlobalConfig $DOMAIN "localhost" "domain" "DOMAIN"
  checkGlobalConfig $SECURE "false" "secure" "SECURE"
  checkGlobalConfig $INGRESS_CONTROLLER "nginx" "consul.ingressClassName" "CONSUL_INGRESS"
  checkGlobalConfig $VKPR_K8S_NAMESPACE "vkpr" "consul.namespace" "NAMESPACE"

  local VKPR_ENV_CONSUL_DOMAIN="consul.${VKPR_ENV_DOMAIN}"
  
  startInfos
  configureRepository
  installConsul
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Consul Install Routine")"
  echoColor "bold" "$(echoColor "blue" "Consul UI Domain:") ${VKPR_ENV_CONSUL_DOMAIN}"
  echoColor "bold" "$(echoColor "blue" "Consul UI HTTPS:") ${VKPR_ENV_SECURE}"
  echoColor "bold" "$(echoColor "blue" "Ingress Controller:") ${VKPR_ENV_CONSUL_INGRESS}"
  echo "=============================="
}

configureRepository() {
  registerHelmRepository hashicorp https://helm.releases.hashicorp.com
}

settingConsul() {
  if [[ $VKPR_ENV_SECURE == true ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .ui.ingress.tls[0].hosts[0] = "'$VKPR_ENV_CONSUL_DOMAIN'" |
      .ui.ingress.tls[0].secretName = "'consul-cert'"
    '
    else
    YQ_VALUES=''$YQ_VALUES' |
      .ui.ingress.annotations = ""
    '
  fi

  mergeVkprValuesHelmArgs "consul" $VKPR_CONSUL_VALUES
}

installConsul() {
  echoColor "bold" "$(echoColor "green" "Installing Consul...")" 
  local YQ_VALUES='.ui.ingress.hosts[0].host = "'$VKPR_ENV_CONSUL_DOMAIN'" | .ui.ingress.ingressClassName = "'$VKPR_ENV_CONSUL_INGRESS'"'
  settingConsul
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_CONSUL_VALUES" \
  | $VKPR_HELM upgrade -i --version "$VKPR_CONSUL_VERSION" \
      --namespace $VKPR_ENV_NAMESPACE --create-namespace \
      --wait -f - consul hashicorp/consul
}