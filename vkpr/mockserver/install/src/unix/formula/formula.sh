#!/bin/bash

runFormula() {
  # Global values
  checkGlobalConfig "$DOMAIN" "localhost" "global.domain" "GLOBAL_DOMAIN"
  checkGlobalConfig "$SECURE" "false" "global.secure" "GLOBAL_SECURE"
  checkGlobalConfig "nginx" "nginx" "global.ingressClassName" "GLOBAL_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "global.namespace" "GLOBAL_NAMESPACE"

  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "mockserver.ingressClassName" "MOCKSERVER_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "mockserver.namespace" "MOCKSERVER_NAMESPACE"
  checkGlobalConfig "$SSL" "false" "mockserver.ssl.enabled" "MOCKSERVER_SSL"
  checkGlobalConfig "$CRT_FILE" "" "mockserver.ssl.crt" "MOCKSERVER_CERTIFICATE"
  checkGlobalConfig "$KEY_FILE" "" "mockserver.ssl.key" "MOCKSERVER_KEY"
  checkGlobalConfig "" "" "mockserver.ssl.secretName" "MOCKSERVER_SSL_SECRET"

  local VKPR_ENV_MOCKSERVER_DOMAIN="mockserver.${VKPR_ENV_GLOBAL_DOMAIN}"
  local VKPR_MOCKSERVER_VALUES; VKPR_MOCKSERVER_VALUES=$(dirname "$0")/utils/mockserver.yaml
  local HELM_NAMESPACE="--create-namespace --namespace $VKPR_ENV_MOCKSERVER_NAMESPACE"

  startInfos
  addRepoMockServer
  installMockServer
}

startInfos() {
  echo "=============================="
  info "VKPR MockServer Install Routine"
  notice "MockServer Domain: $VKPR_ENV_MOCKSERVER_DOMAIN"
  notice "Ingress Controller: $VKPR_ENV_MOCKSERVER_INGRESS_CLASS_NAME"
  echo "=============================="
}

addRepoMockServer() {
  registerHelmRepository mockserver https://www.mock-server.com
}

installMockServer() {
  local YQ_VALUES=".ingress.hosts[0] = \"$VKPR_ENV_MOCKSERVER_DOMAIN\""
  settingMockServer

  if [[ $DRY_RUN == true ]]; then
    echoColor "bold" "---"
    mergeVkprValuesHelmArgs "mockserver" "$VKPR_MOCKSERVER_VALUES"
    $VKPR_YQ eval "$YQ_VALUES" "$VKPR_MOCKSERVER_VALUES"
  else
    info "Installing MockServer..."
    $VKPR_YQ eval -i "$YQ_VALUES" "$VKPR_MOCKSERVER_VALUES"
    mergeVkprValuesHelmArgs "mockserver" "$VKPR_MOCKSERVER_VALUES"
    # shellcheck disable=SC2086
    $VKPR_HELM upgrade -i --version "$VKPR_MOCKSERVER_VERSION" $HELM_NAMESPACE \
      --wait -f "$VKPR_MOCKSERVER_VALUES" mockserver mockserver/mockserver
  fi
}

settingMockServer() {
  YQ_VALUES="$YQ_VALUES |
    .ingress.enabled = true |
    .ingress.ingressClass.enabled = true |
    .ingress.ingressClass.name = \"$VKPR_ENV_MOCKSERVER_INGRESS_CLASS_NAME\"
  "
  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .ingress.tls[0].hosts[0] = \"$VKPR_ENV_MOCKSERVER_DOMAIN\" |
      .ingress.tls[0].secretName = \"mockserver-cert\"
    "
  fi

  if [[ "$VKPR_ENV_MOCKSERVER_SSL" == "true" ]]; then
    if [[ "$VKPR_ENV_MOCKSERVER_SSL_SECRET" == "" ]]; then
      VKPR_ENV_MOCKSERVER_SSL_SECRET="mockserver-certificate"
      $VKPR_KUBECTL create secret tls $VKPR_ENV_MOCKSERVER_SSL_SECRET -n "$VKPR_ENV_MOCKSERVER_NAMESPACE" \
        --cert="$VKPR_ENV_MOCKSERVER_CERTIFICATE" \
        --key="$VKPR_ENV_MOCKSERVER_KEY"
    fi 
    YQ_VALUES="$YQ_VALUES |
      .ingress.tls[0].hosts[0] = \"$VKPR_ENV_MOCKSERVER_DOMAIN\" |
      .ingress.tls[0].secretName = \"$VKPR_ENV_MOCKSERVER_SSL_SECRET\"
     "
  fi

  settingMockServerProvider
}

settingMockServerProvider() {
  ACTUAL_CONTEXT=$($VKPR_KUBECTL config get-contexts --no-headers | grep "\*" | xargs | awk -F " " '{print $2}')
  if [[ "$VKPR_ENV_GLOBAL_PROVIDER" == "okteto" ]] || [[ $ACTUAL_CONTEXT == "cloud_okteto_com" ]]; then
    OKTETO_NAMESPACE=$($VKPR_KUBECTL config get-contexts --no-headers | grep "\*" | xargs | awk -F " " '{print $NF}')
    HELM_NAMESPACE=""
    YQ_VALUES="$YQ_VALUES |
      .ingress.enabled = \"false\" |
      .ingress.hosts[0] = \"mockserver-${OKTETO_NAMESPACE}.cloud.okteto.net\" |
      .service.annotations.[\"dev.okteto.com/auto-ingress\"] = \"true\" |
      .app.proxyRemoteHost = \"localhost\" |
      .app.proxyRemotePort = \"1080\"
    "
  fi
}