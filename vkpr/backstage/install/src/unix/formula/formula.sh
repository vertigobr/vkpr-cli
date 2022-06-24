#!/bin/bash

runFormula() {
  # Global values
  checkGlobalConfig "" "" "global.provider" "GLOBAL_PROVIDER"
  checkGlobalConfig "$DOMAIN" "localhost" "global.domain" "GLOBAL_DOMAIN"
  checkGlobalConfig "$SECURE" "false" "global.secure" "GLOBAL_SECURE"
  checkGlobalConfig "nginx" "nginx" "global.ingressClassName" "GLOBAL_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "global.namespace" "GLOBAL_NAMESPACE"

  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "backstage.ingressClassName" "BACKSTAGE_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "backstage.namespace" "BACKSTAGE_NAMESPACE"

  local VKPR_ENV_BACKSTAGE_DOMAIN="backstage.${VKPR_ENV_GLOBAL_DOMAIN}" \
        RIT_CREDENTIALS_PATH=~/.rit/credentials/default
  local VKPR_BACKSTAGE_VALUES; VKPR_BACKSTAGE_VALUES=$(dirname "$0")/utils/backstage.yaml
  local HELM_NAMESPACE="--namespace=$VKPR_ENV_BACKSTAGE_NAMESPACE --create-namespace"

  startInfos
  addRepoBackstage
  installBackstage
}

startInfos() {
  echo "=============================="
  info "VKPR Backstage Install Routine"
  notice "Backstage Domain: $VKPR_ENV_BACKSTAGE_DOMAIN"
  notice "Ingress Controller: $VKPR_ENV_BACKSTAGE_INGRESS_CLASS_NAME"
  echo "=============================="
}

addRepoBackstage() {
  registerHelmRepository veecode-platform https://vfipaas.github.io/public-charts/
}

installBackstage() {
  local YQ_VALUES=".ingress.hosts[0].host = \"$VKPR_ENV_BACKSTAGE_DOMAIN\" |
   .ingress.hosts[0].paths[0].path = \"/\"|
    .ingress.hosts[0].paths[0].pathType = \"ImplementationSpecific\"
  "
  settingBackstage

  if [[ $DRY_RUN == true ]]; then
    bold "---"
    mergeVkprValuesHelmArgs "backstage" "$VKPR_BACKSTAGE_VALUES"  
    $VKPR_YQ eval "$YQ_VALUES" "$VKPR_BACKSTAGE_VALUES"  
  else
    info "Installing backstage..."
    $VKPR_YQ eval -i "$YQ_VALUES" "$VKPR_BACKSTAGE_VALUES"
    mergeVkprValuesHelmArgs "backstage" "$VKPR_BACKSTAGE_VALUES"
    # shellcheck disable=SC2086
    $VKPR_HELM upgrade -i --version "$VKPR_BACKSTAGE_VERSION" $HELM_NAMESPACE \
      --wait -f "$VKPR_BACKSTAGE_VALUES" backstage veecode-platform/devportal
  fi
}

settingBackstage() {
  YQ_VALUES="$YQ_VALUES |
    .ingress.enabled = true |
    .ingress.ingressClassName = \"$VKPR_ENV_BACKSTAGE_INGRESS_CLASS_NAME\" |
    .appConfig.app.baseUrl = \"http://$VKPR_ENV_BACKSTAGE_DOMAIN/\" |
    .appConfig.backend.baseUrl = \"http://$VKPR_ENV_BACKSTAGE_DOMAIN/\" |
    .auth.okta.clientId = \"$(echo -n "$($VKPR_JQ -r .credential.clientid $RIT_CREDENTIALS_PATH/okta)")\" |
    .auth.okta.clientSecret = \"$(echo -n "$($VKPR_JQ -r .credential.clientsecret $RIT_CREDENTIALS_PATH/okta)")\" |
    .auth.okta.audience = \"$(echo -n "$($VKPR_JQ -r .credential.audience $RIT_CREDENTIALS_PATH/okta)")\" |
    .gihubToken = \"$(echo -n "$($VKPR_JQ -r .credential.token $RIT_CREDENTIALS_PATH/github)")\" |
    .githubSpecHouseURL = \"$(echo -n "$($VKPR_JQ -r .credential.spechouseurl $RIT_CREDENTIALS_PATH/github)")\"
  "

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .ingress.tls[0].hosts[0] = \"$VKPR_ENV_BACKSTAGE_DOMAIN\" |
      .ingress.tls[0].secretName = \"backstage-cert\"
    "
  fi

  settingBackstageProvider
}

settingBackstageProvider() {
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