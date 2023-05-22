#!/usr/bin/env bash

runFormula() {
  local VKPR_ENV_MOCKSERVER_DOMAIN VKPR_MOCKSERVER_VALUES HELM_ARGS;
  formulaInputs
  validateInputs

  VKPR_ENV_MOCKSERVER_DOMAIN="mockserver.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_MOCKSERVER_VALUES=$(dirname "$0")/utils/mockserver.yaml

  startInfos
  settingMockServer
  [ $DRY_RUN = false ] && registerHelmRepository mockserver https://www.mock-server.com
  installApplication "mockserver" "mockserver/mockserver" "$VKPR_ENV_MOCKSERVER_NAMESPACE" "$VKPR_MOCKSERVER_VERSION" "$VKPR_MOCKSERVER_VALUES" "$HELM_ARGS"
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR MockServer Install Routine"
  boldNotice "Domain: $VKPR_ENV_MOCKSERVER_DOMAIN"
  boldNotice "Secure: $VKPR_ENV_GLOBAL_SECURE"
  boldNotice "Namespace: $VKPR_ENV_MOCKSERVER_NAMESPACE"
  boldNotice "Ingress Controller: $VKPR_ENV_MOCKSERVER_INGRESS_CLASS_NAME"
  bold "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "mockserver.ingressClassName" "MOCKSERVER_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "mockserver.namespace" "MOCKSERVER_NAMESPACE"
  checkGlobalConfig "$SSL" "false" "mockserver.ssl.enabled" "MOCKSERVER_SSL"
  checkGlobalConfig "$CRT_FILE" "" "mockserver.ssl.crt" "MOCKSERVER_SSL_CERTIFICATE"
  checkGlobalConfig "$KEY_FILE" "" "mockserver.ssl.key" "MOCKSERVER_SSL_KEY"
  checkGlobalConfig "" "" "mockserver.ssl.secretName" "MOCKSERVER_SSL_SECRET"
}

validateInputs() {
  # App values
  validateMockServerDomain "$VKPR_ENV_GLOBAL_DOMAIN"
  validateMockServerSecure "$VKPR_ENV_GLOBAL_SECURE"
  validateMockServerIngressClassName "$VKPR_ENV_MOCKSERVER_INGRESS_CLASS_NAME"
  validateMockServerNamespace "$VKPR_ENV_MOCKSERVER_NAMESPACE"

  validateMockServerSSL "$VKPR_ENV_MOCKSERVER_SSL"
  if [[ "$VKPR_ENV_MOCKSERVER_SSL" = true ]]; then
    validateMockServerCertificate "$VKPR_ENV_MOCKSERVER_SSL_CERTIFICATE"
    validateMockServerKey "$VKPR_ENV_MOCKSERVER_SSL_KEY"
  fi
}

settingMockServer() {
  YQ_VALUES=".ingress.hosts[0] = \"$VKPR_ENV_MOCKSERVER_DOMAIN\" |
    .ingress.ingressClass.name = \"$VKPR_ENV_MOCKSERVER_INGRESS_CLASS_NAME\"
  "

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .ingress.tls[0].hosts[0] = \"$VKPR_ENV_MOCKSERVER_DOMAIN\" |
      .ingress.tls[0].secretName = \"mockserver-cert\"
    "
  fi

  if [[ "$VKPR_ENV_MOCKSERVER_SSL" == "true" ]] && [[ $(checkPodName "$VKPR_ENV_GRAFANA_NAMESPACE" "prometheus-stack-grafana") == "true" ]]; then
    if [[ "$VKPR_ENV_MOCKSERVER_SSL_SECRET" == "" ]]; then
      VKPR_ENV_MOCKSERVER_SSL_SECRET="mockserver-certificate"
      $VKPR_KUBECTL create secret tls $VKPR_ENV_MOCKSERVER_SSL_SECRET -n "$VKPR_ENV_MOCKSERVER_NAMESPACE" \
        --cert="$VKPR_ENV_MOCKSERVER_SSL_CERTIFICATE" \
        --key="$VKPR_ENV_MOCKSERVER_SSL_KEY"
    fi
    YQ_VALUES="$YQ_VALUES |
      .ingress.tls[0].hosts[0] = \"$VKPR_ENV_MOCKSERVER_DOMAIN\" |
      .ingress.tls[0].secretName = \"$VKPR_ENV_MOCKSERVER_SSL_SECRET\"
     "
  fi

  settingMockServerProvider

  debug "YQ_CONTENT = $YQ_VALUES"
}

settingMockServerProvider() {
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    YQ_VALUES="$YQ_VALUES |
      .ingress.enabled = false |
      .service.annotations.[\"dev.okteto.com/auto-ingress\"] = \"true\" |
      .app.proxyRemoteHost = \"localhost\" |
      .app.proxyRemotePort = \"1080\"
    "
  fi
}
