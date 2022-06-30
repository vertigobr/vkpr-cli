#!/bin/bash

runFormula() {
  # Global values
  checkGlobalConfig "$DOMAIN" "localhost" "global.domain" "GLOBAL_DOMAIN"
  checkGlobalConfig "$SECURE" "false" "global.secure" "GLOBAL_SECURE"
  checkGlobalConfig "nginx" "nginx" "global.ingressClassName" "GLOBAL_INGRESS"
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "global.namespace" "GLOBAL_NAMESPACE"
  
  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS" "$VKPR_ENV_GLOBAL_INGRESS" "consul.ingressClassName" "CONSUL_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "consul.namespace" "CONSUL_NAMESPACE"
  checkGlobalConfig "$SSL" "false" "consul.ssl.enabled" "CONSUL_SSL"
  checkGlobalConfig "$CRT_FILE" "" "consul.ssl.crt" "CONSUL_CERTIFICATE"
  checkGlobalConfig "$KEY_FILE" "" "consul.ssl.key" "CONSUL_KEY"
  checkGlobalConfig "" "" "consul.ssl.secretName" "CONSUL_SSL_SECRET"

  local VKPR_ENV_CONSUL_DOMAIN="consul.${VKPR_ENV_GLOBAL_DOMAIN}"
  local VKPR_CONSUL_VALUES; VKPR_CONSUL_VALUES="$(dirname "$0")"/utils/consul.yaml
  
  startInfos
  configureRepository
  installConsul
}

startInfos() {
  echo "=============================="
  bold "$(info "VKPR Consul Install Routine")"
  bold "$(notice "Consul UI Domain:") ${VKPR_ENV_CONSUL_DOMAIN}"
  bold "$(notice "Consul UI HTTPS:") ${VKPR_ENV_GLOBAL_SECURE}"
  bold "$(notice "Ingress Controller:") ${VKPR_ENV_CONSUL_INGRESS_CLASS_NAME}"
  echo "=============================="
}

configureRepository() {
  registerHelmRepository hashicorp https://helm.releases.hashicorp.com
}

installConsul() {
  local YQ_VALUES=".ui.ingress.hosts[0].host = \"$VKPR_ENV_CONSUL_DOMAIN\" | .ui.ingress.ingressClassName = \"$VKPR_ENV_CONSUL_INGRESS_CLASS_NAME\""
  settingConsul

  if [[ $DRY_RUN == true ]]; then
    echoColor "bold" "---"
    mergeVkprValuesHelmArgs "consul" "$VKPR_CONSUL_VALUES"
    $VKPR_YQ eval "$YQ_VALUES" "$VKPR_CONSUL_VALUES"    
  else
    bold "$(info "Installing Consul...")" 
    $VKPR_YQ eval -i "$YQ_VALUES" "$VKPR_CONSUL_VALUES"
    mergeVkprValuesHelmArgs "consul" "$VKPR_CONSUL_VALUES"
    $VKPR_HELM upgrade -i --version "$VKPR_CONSUL_VERSION" \
      --namespace "$VKPR_ENV_CONSUL_NAMESPACE" --create-namespace \
      --wait -f "$VKPR_CONSUL_VALUES" consul hashicorp/consul
  fi
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

  if [[ "$VKPR_ENV_CONSUL_SSL" == "true" ]]; then
    if [[ "$VKPR_ENV_CONSUL_SSL_SECRET" == "" ]]; then
      VKPR_ENV_CONSUL_SSL_SECRET="consul-certificate"
      $VKPR_KUBECTL create secret tls $VKPR_ENV_CONSUL_SSL_SECRET -n "$VKPR_ENV_CONSUL_NAMESPACE" \
        --cert="$VKPR_ENV_CONSUL_CERTIFICATE" \
        --key="$VKPR_ENV_CONSUL_KEY"
    fi 
    YQ_VALUES="$YQ_VALUES |
      .ui.ingress.tls[0].hosts[0] = \"$VKPR_ENV_CONSUL_DOMAIN\" |
      .ui.ingress.tls[0].secretName = \"$VKPR_ENV_CONSUL_SSL_SECRET\"
     "
  fi
}
