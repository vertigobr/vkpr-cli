#!/bin/bash

runFormula() {
  # Global values
  checkGlobalConfig "$DOMAIN" "localhost" "global.domain" "GLOBAL_DOMAIN"
  checkGlobalConfig "$SECURE" "false" "global.secure" "GLOBAL_SECURE"
  checkGlobalConfig "nginx" "nginx" "global.ingressClassName" "GLOBAL_INGRESS"
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "global.namespace" "GLOBAL_NAMESPACE"
  
  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS" "$VKPR_ENV_GLOBAL_INGRESS" "consul.ingressClassName" "CONSUL_INGRESS"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "consul.namespace" "CONSUL_NAMESPACE"

  local VKPR_ENV_CONSUL_DOMAIN="consul.${VKPR_ENV_GLOBAL_DOMAIN}"
  local VKPR_CONSUL_VALUES; VKPR_CONSUL_VALUES="$(dirname "$0")"/utils/consul.yaml
  
  startInfos
  configureRepository
  installConsul
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Consul Install Routine")"
  echoColor "bold" "$(echoColor "blue" "Consul UI Domain:") ${VKPR_ENV_CONSUL_DOMAIN}"
  echoColor "bold" "$(echoColor "blue" "Consul UI HTTPS:") ${VKPR_ENV_GLOBAL_SECURE}"
  echoColor "bold" "$(echoColor "blue" "Ingress Controller:") ${VKPR_ENV_CONSUL_INGRESS}"
  echo "=============================="
}

configureRepository() {
  registerHelmRepository hashicorp https://helm.releases.hashicorp.com
}

settingConsul() {
  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .ui.ingress.tls[0].hosts[0] = \"$VKPR_ENV_CONSUL_DOMAIN\" |
      .ui.ingress.tls[0].secretName = \"consul-cert\"
    "
    else
    YQ_VALUES="$YQ_VALUES |
      .ui.ingress.annotations = \"\"
    "
  fi
}

installConsul() {
  echoColor "bold" "$(echoColor "green" "Installing Consul...")" 
  local YQ_VALUES=".ui.ingress.hosts[0].host = \"$VKPR_ENV_CONSUL_DOMAIN\" | .ui.ingress.ingressClassName = \"$VKPR_ENV_CONSUL_INGRESS\""
  settingConsul

  $VKPR_YQ eval -i "$YQ_VALUES" "$VKPR_CONSUL_VALUES"
  mergeVkprValuesHelmArgs "consul" "$VKPR_CONSUL_VALUES"
  $VKPR_HELM upgrade -i --version "$VKPR_CONSUL_VERSION" \
    --namespace "$VKPR_ENV_CONSUL_NAMESPACE" --create-namespace \
    --wait -f "$VKPR_CONSUL_VALUES" consul hashicorp/consul
}