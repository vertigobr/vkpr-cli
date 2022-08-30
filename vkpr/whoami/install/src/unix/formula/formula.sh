#!/usr/bin/env bash

runFormula() {
  local VKPR_ENV_WHOAMI_DOMAIN VKPR_WHOAMI_VALUES HELM_ARGS;

  VKPR_ENV_WHOAMI_DOMAIN="whoami.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_WHOAMI_VALUES=$(dirname "$0")/utils/whoami.yaml

  formulaInputs
  validateInputs

  startInfos
  settingWhoami
  [ $DRY_RUN = false ] && registerHelmRepository cowboysysop https://cowboysysop.github.io/charts/
  installApplication "whoami" "cowboysysop/whoami" "$VKPR_ENV_WHOAMI_NAMESPACE" "$VKPR_WHOAMI_VERSION" "$VKPR_WHOAMI_VALUES" "$HELM_ARGS"
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Whoami Install Routine"
  boldNotice "Domain: $VKPR_ENV_WHOAMI_DOMAIN"
  boldNotice "Secure: $VKPR_ENV_GLOBAL_SECURE"
  boldNotice "Namespace: $VKPR_ENV_WHOAMI_NAMESPACE"
  boldNotice "Ingress Controller: $VKPR_ENV_WHOAMI_INGRESS_CLASS_NAME"
  bold "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "$SSL" "false" "whoami.ssl.enabled" "WHOAMI_SSL"
  checkGlobalConfig "$CRT_FILE" "" "whoami.ssl.crt" "WHOAMI_SSL_CERTIFICATE"
  checkGlobalConfig "$KEY_FILE" "" "whoami.ssl.key" "WHOAMI_SSL_KEY"
  checkGlobalConfig "" "" "whoami.ssl.secretName" "WHOAMI_SSL_SECRET"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "whoami.ingressClassName" "WHOAMI_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "whoami.namespace" "WHOAMI_NAMESPACE"
}

validateInputs() {
  validateWhoamiDomain "$VKPR_ENV_WHOAMI_DOMAIN"
  validateWhoamiSecure "$VKPR_ENV_GLOBAL_SECURE"
  validateWhoamiSsl "$VKPR_ENV_WHOAMI_SSL"
  if [[ "$VKPR_ENV_WHOAMI_SSL" == true  ]] ; then
    validateWhoamiSslCrtPath "$VKPR_ENV_WHOAMI_SSL_CERTIFICATE"
    validateWhoamiSslKeyPath "$VKPR_ENV_WHOAMI_SSL_KEY"
  fi
}

settingWhoami() {
  YQ_VALUES=".ingress.hosts[0].host = \"$VKPR_ENV_WHOAMI_DOMAIN\" |
    .ingress.annotations.[\"kubernetes.io/ingress.class\"] = \"$VKPR_ENV_WHOAMI_INGRESS_CLASS_NAME\"
  "

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .ingress.tls[0].hosts[0] = \"$VKPR_ENV_WHOAMI_DOMAIN\" |
      .ingress.tls[0].secretName = \"whoami-cert\"
    "
  fi

  if [[ "$VKPR_ENV_WHOAMI_SSL" == "true" ]]; then
    if [[ "$VKPR_ENV_WHOAMI_SSL_SECRET" == "" ]]; then
      VKPR_ENV_WHOAMI_SSL_SECRET="whoami-certificate"
      $VKPR_KUBECTL create secret tls $VKPR_ENV_WHOAMI_SSL_SECRET -n "$VKPR_ENV_WHOAMI_NAMESPACE" \
        --cert="$VKPR_ENV_WHOAMI_SSL_CERTIFICATE" \
        --key="$VKPR_ENV_WHOAMI_SSL_KEY"
    fi
    YQ_VALUES="$YQ_VALUES |
      .ingress.tls[0].hosts[0] = \"$VKPR_ENV_WHOAMI_DOMAIN\" |
      .ingress.tls[0].secretName = \"$VKPR_ENV_WHOAMI_SSL_SECRET\"
     "
  fi

  settingWhoamiEnvironment

  debug "YQ_CONTENT = $YQ_VALUES"
}

settingWhoamiEnvironment() {
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    YQ_VALUES="$YQ_VALUES |
      .ingress.enabled = false |
      .service.annotations.[\"dev.okteto.com/auto-ingress\"] = \"true\"
    "
  fi
}
