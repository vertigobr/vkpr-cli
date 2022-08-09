#!/usr/bin/env bash

runFormula() {
  local VKPR_ENV_DEVPORTAL_DOMAIN VKPR_DEVPORTAL_VALUES HELM_ARGS;
  setCredentials
  formulaInputs
  validateInputs

  VKPR_ENV_DEVPORTAL_DOMAIN="devportal.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_DEVPORTAL_VALUES=$(dirname "$0")/utils/devportal.yaml

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

setCredentials() {
  OKTA_CLIENT_ID="$($VKPR_JQ -r '.credential.clientid' $VKPR_CREDENTIAL/okta)"
  OKTA_CLIENT_SECRET="$($VKPR_JQ -r '.credential.clientsecret' $VKPR_CREDENTIAL/okta)"
  OKTA_CLIENT_AUDIENCE="$($VKPR_JQ -r '.credential.audience' $VKPR_CREDENTIAL/okta)"
  GITHUB_TOKEN="$($VKPR_JQ -r '.credential.token' $VKPR_CREDENTIAL/github)"
}

validateInputs() {
  validateDevportalDomain "$VKPR_ENV_GLOBAL_DOMAIN"
  validateDevportalSecure "$VKPR_ENV_GLOBAL_SECURE"
  validateDevportalIngressClassName "$VKPR_ENV_DEVPORTAL_INGRESS_CLASS_NAME"
  validateDevportalNamespace "$VKPR_ENV_DEVPORTAL_NAMESPACE"

  validateOktaClientId "$OKTA_CLIENT_ID"
  validateOktaClientSecret "$OKTA_CLIENT_SECRET"
  validateOktaClientAudience "$OKTA_CLIENT_AUDIENCE"
}

settingDevportal() {
  YQ_VALUES=".ingress.hosts[0].host = \"$VKPR_ENV_DEVPORTAL_DOMAIN\" |
    .ingress.ingressClassName = \"$VKPR_ENV_DEVPORTAL_INGRESS_CLASS_NAME\" |
    .appConfig.app.baseUrl = \"http://$VKPR_ENV_DEVPORTAL_DOMAIN/\" |
    .appConfig.backend.baseUrl = \"http://$VKPR_ENV_DEVPORTAL_DOMAIN/\" |
    .auth.okta.clientId = \"$OKTA_CLIENT_ID\" |
    .auth.okta.clientSecret = \"$OKTA_CLIENT_SECRET\" |
    .auth.okta.audience = \"$OKTA_CLIENT_AUDIENCE\" |
    .githubToken = \"$GITHUB_TOKEN\" |
    .githubSpecHouseURL = \"$GITHUB_SPECHOUSEURL\"
  "

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .ingress.tls[0].hosts[0] = \"$VKPR_ENV_DEVPORTAL_DOMAIN\" |
      .ingress.tls[0].secretName = \"devportal-cert\"|
      .appConfig.app.baseUrl = \"https://$VKPR_ENV_DEVPORTAL_DOMAIN/\" |
      .appConfig.backend.baseUrl = \"https://$VKPR_ENV_DEVPORTAL_DOMAIN/\"
    "
  fi

  if [[ $VKPR_ENV_GLOBAL_DOMAIN == "localhost" ]]; then
    YQ_VALUES="$YQ_VALUES |
      .appConfig.app.baseUrl = \"http://$VKPR_ENV_DEVPORTAL_DOMAIN:8000/\" |
      .appConfig.backend.baseUrl = \"http://$VKPR_ENV_DEVPORTAL_DOMAIN:8000/\"
    "
  fi

  settingDevportalProvider

  debug "YQ_CONTENT = $YQ_VALUES"
}

settingDevportalProvider() {
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    OKTETO_NAMESPACE=$($VKPR_KUBECTL config get-contexts --no-headers | grep "\*" | xargs | awk -F " " '{print $NF}')
    YQ_VALUES="$YQ_VALUES |
      .ingress.enabled = false |
      .service.annotations.[\"dev.okteto.com/auto-ingress\"] = \"true\" |
      .appConfig.app.baseUrl = \"https://devportal-$OKTETO_NAMESPACE.cloud.okteto.net/\" |
      .appConfig.backend.baseUrl = \"https://devportal-$OKTETO_NAMESPACE.cloud.okteto.net/\"
    "
  fi

}
