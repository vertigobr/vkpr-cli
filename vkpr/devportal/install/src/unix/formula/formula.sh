#!/bin/bash

runFormula() {
  local VKPR_ENV_DEVPORTAL_DOMAIN VKPR_DEVPORTAL_VALUES RIT_CREDENTIALS_PATH HELM_ARGS;
  formulaInputs
  validateInputs

  VKPR_ENV_DEVPORTAL_DOMAIN="devportal.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_DEVPORTAL_VALUES=$(dirname "$0")/utils/devportal.yaml
  RIT_CREDENTIALS_PATH=~/.rit/credentials/default

  startInfos
  settingDevportal
  [ $DRY_RUN = false ] && registerHelmRepository veecode-platform https://vfipaas.github.io/public-charts/
  installApplication "devportal" "veecode-platform/devportal" "$VKPR_ENV_DEVPORTAL_NAMESPACE" "$VKPR_DEVPORTAL_VERSION" "$VKPR_DEVPORTAL_VALUES" "$HELM_ARGS"
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Devportal Install Routine"
  boldNotice "Domain: $VKPR_ENV_DEVPORTAL_DOMAIN"
  boldNotice "Secure: $VKPR_ENV_GLOBAL_SECURE"
  boldNotice "Namespace: $VKPR_ENV_DEVPORTAL_NAMESPACE"
  boldNotice "Ingress Controller: $VKPR_ENV_DEVPORTAL_INGRESS_CLASS_NAME"
  bold "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "devportal.ingressClassName" "DEVPORTAL_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "devportal.namespace" "DEVPORTAL_NAMESPACE"
}

validateInputs() {
}

settingDevportal() {
  local YQ_VALUES=".ingress.enabled = true |
    .ingress.hosts[0].host = \"$VKPR_ENV_DEVPORTAL_DOMAIN\" |
    .ingress.hosts[0].paths[0].path = \"/\"|
    .ingress.hosts[0].paths[0].pathType = \"ImplementationSpecific\" |
    .ingress.ingressClassName = \"$VKPR_ENV_DEVPORTAL_INGRESS_CLASS_NAME\" |
    .appConfig.app.baseUrl = \"http://$VKPR_ENV_DEVPORTAL_DOMAIN/\" |
    .appConfig.backend.baseUrl = \"http://$VKPR_ENV_DEVPORTAL_DOMAIN/\" |
    .auth.okta.clientId = \"$(echo -n "$($VKPR_JQ -r .credential.clientid $RIT_CREDENTIALS_PATH/okta)")\" |
    .auth.okta.clientSecret = \"$(echo -n "$($VKPR_JQ -r .credential.clientsecret $RIT_CREDENTIALS_PATH/okta)")\" |
    .auth.okta.audience = \"$(echo -n "$($VKPR_JQ -r .credential.audience $RIT_CREDENTIALS_PATH/okta)")\" |
    .gihubToken = \"$(echo -n "$($VKPR_JQ -r .credential.token $RIT_CREDENTIALS_PATH/github)")\" |
    .githubSpecHouseURL = \"$(echo -n "$($VKPR_JQ -r .credential.spechouseurl $RIT_CREDENTIALS_PATH/github)")\"
  "

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .ingress.tls[0].hosts[0] = \"$VKPR_ENV_DEVPORTAL_DOMAIN\" |
      .ingress.tls[0].secretName = \"devportal-cert\"
    "
  fi

  settingDevportalProvider

  debug "YQ_CONTENT = $YQ_VALUES"
}

settingDevportalProvider() {
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    YQ_VALUES="$YQ_VALUES |
      .ingress.enabled = false |
      .service.annotations.[\"dev.okteto.com/auto-ingress\"] = \"true\"
    "
  fi
}