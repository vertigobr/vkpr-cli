#!/bin/bash

runFormula() {
  # Global values
  checkGlobalConfig "" "" "global.provider" "GLOBAL_PROVIDER"
  checkGlobalConfig "$DOMAIN" "localhost" "global.domain" "GLOBAL_DOMAIN"
  checkGlobalConfig "$SECURE" "false" "global.secure" "GLOBAL_SECURE"
  checkGlobalConfig "nginx" "nginx" "global.ingressClassName" "GLOBAL_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "global.namespace" "GLOBAL_NAMESPACE"

  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "devportal.ingressClassName" "DEVPORTAL_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "devportal.namespace" "DEVPORTAL_NAMESPACE"

  local VKPR_ENV_DEVPORTAL_DOMAIN="devportal.${VKPR_ENV_GLOBAL_DOMAIN}" \
        RIT_CREDENTIALS_PATH=~/.rit/credentials/default
  local VKPR_DEVPORTAL_VALUES; VKPR_DEVPORTAL_VALUES=$(dirname "$0")/utils/devportal.yaml
  local HELM_NAMESPACE="--namespace=$VKPR_ENV_DEVPORTAL_NAMESPACE --create-namespace"

  startInfos
  addRepoDevportal
  installDevportal
}

startInfos() {
  echo "=============================="
  info "VKPR Devportal Install Routine"
  notice "Devportal Domain: $VKPR_ENV_DEVPORTAL_DOMAIN"
  notice "Ingress Controller: $VKPR_ENV_DEVPORTAL_INGRESS_CLASS_NAME"
  echo "=============================="
}

addRepoDevportal() {
  registerHelmRepository veecode-platform https://vfipaas.github.io/public-charts/
}

installDevportal() {
  local YQ_VALUES=".ingress.hosts[0].host = \"$VKPR_ENV_DEVPORTAL_DOMAIN\" |
   .ingress.hosts[0].paths[0].path = \"/\"|
    .ingress.hosts[0].paths[0].pathType = \"ImplementationSpecific\"
  "
  settingDevportal

  if [[ $DRY_RUN == true ]]; then
    bold "---"
    mergeVkprValuesHelmArgs "devportal" "$VKPR_DEVPORTAL_VALUES"  
    $VKPR_YQ eval "$YQ_VALUES" "$VKPR_DEVPORTAL_VALUES"  
  else
    info "Installing devportal..."
    $VKPR_YQ eval -i "$YQ_VALUES" "$VKPR_DEVPORTAL_VALUES"
    mergeVkprValuesHelmArgs "devportal" "$VKPR_DEVPORTAL_VALUES"
    # shellcheck disable=SC2086
    $VKPR_HELM upgrade -i --version "$VKPR_DEVPORTAL_VERSION" $HELM_NAMESPACE \
      --wait -f "$VKPR_DEVPORTAL_VALUES" devportal veecode-platform/devportal
  fi
}

settingDevportal() {
  YQ_VALUES="$YQ_VALUES |
    .ingress.enabled = true |
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
}

settingDevportalProvider() {
  ACTUAL_CONTEXT=$($VKPR_KUBECTL config get-contexts --no-headers | grep "\*" | xargs | awk -F " " '{print $2}')
  if [[ "$VKPR_ENV_GLOBAL_PROVIDER" == "okteto" ]] || [[ $ACTUAL_CONTEXT == "cloud_okteto_com" ]]; then
    OKTETO_NAMESPACE=$($VKPR_KUBECTL config get-contexts --no-headers | grep "\*" | xargs | awk -F " " '{print $NF}')
    HELM_NAMESPACE=""
    YQ_VALUES="$YQ_VALUES |
      .ingress.enabled = \"false\" |
      .service.annotations.[\"dev.okteto.com/auto-ingress\"] = \"true\"
    "
  fi
} 