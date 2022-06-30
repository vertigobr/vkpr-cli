#!/bin/bash

runFormula() {
  # Global values
  checkGlobalConfig "" "" "global.provider" "GLOBAL_PROVIDER"
  checkGlobalConfig "$DOMAIN" "localhost" "global.domain" "GLOBAL_DOMAIN"
  checkGlobalConfig "$SECURE" "false" "global.secure" "GLOBAL_SECURE"
  checkGlobalConfig "nginx" "nginx" "global.ingressClassName" "GLOBAL_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "global.namespace" "GLOBAL_NAMESPACE"

  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "whoami.ingressClassName" "WHOAMI_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "whoami.namespace" "WHOAMI_NAMESPACE"
  checkGlobalConfig "$SSL" "false" "whoami.ssl.enabled" "WHOAMI_SSL"
  checkGlobalConfig "$CRT_FILE" "" "whoami.ssl.crt" "WHOAMI_CERTIFICATE"
  checkGlobalConfig "$KEY_FILE" "" "whoami.ssl.key" "WHOAMI_KEY"
  checkGlobalConfig "" "" "whoami.ssl.secretName" "WHOAMI_SSL_SECRET"

  validateWhoamiSecure "$VKPR_ENV_GLOBAL_SECURE"

  local VKPR_ENV_WHOAMI_DOMAIN="whoami.${VKPR_ENV_GLOBAL_DOMAIN}"
  local VKPR_WHOAMI_VALUES; VKPR_WHOAMI_VALUES=$(dirname "$0")/utils/whoami.yaml
  local HELM_NAMESPACE="--create-namespace --namespace $VKPR_ENV_WHOAMI_NAMESPACE"

  startInfos
  addRepoWhoami
  installWhoami
}

startInfos() {
  echo "=============================="
  info "VKPR Whoami Install Routine"
  notice "Whoami Domain: $VKPR_ENV_WHOAMI_DOMAIN"
  notice "Ingress Controller: $VKPR_ENV_WHOAMI_INGRESS_CLASS_NAME"
  echo "=============================="
}

addRepoWhoami() {
  registerHelmRepository cowboysysop https://cowboysysop.github.io/charts/
}

installWhoami() {
  local YQ_VALUES=".ingress.hosts[0].host = \"$VKPR_ENV_WHOAMI_DOMAIN\""
  settingWhoami

  if [[ $DRY_RUN == true ]]; then
    bold "---"
    mergeVkprValuesHelmArgs "whoami" "$VKPR_WHOAMI_VALUES"
    $VKPR_YQ eval "$YQ_VALUES" "$VKPR_WHOAMI_VALUES"
  else
    info "Installing whoami..."
    $VKPR_YQ eval -i "$YQ_VALUES" "$VKPR_WHOAMI_VALUES"
    mergeVkprValuesHelmArgs "whoami" "$VKPR_WHOAMI_VALUES"
    # shellcheck disable=SC2086
    $VKPR_HELM upgrade -i --version "$VKPR_WHOAMI_VERSION" $HELM_NAMESPACE \
      --wait -f "$VKPR_WHOAMI_VALUES" whoami cowboysysop/whoami
  fi
}

settingWhoami() {
  YQ_VALUES="$YQ_VALUES |
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
        --cert="$VKPR_ENV_WHOAMI_CERTIFICATE" \
        --key="$VKPR_ENV_WHOAMI_KEY"
    fi 
    YQ_VALUES="$YQ_VALUES |
      .ingress.tls[0].hosts[0] = \"$VKPR_ENV_WHOAMI_DOMAIN\" |
      .ingress.tls[0].secretName = \"$VKPR_ENV_WHOAMI_SSL_SECRET\"
     "
  fi

  settingWhoamiProvider
}

settingWhoamiProvider() {
  ACTUAL_CONTEXT=$($VKPR_KUBECTL config get-contexts --no-headers | grep "\*" | xargs | awk -F " " '{print $2}')
  if [[ "$VKPR_ENV_GLOBAL_PROVIDER" == "okteto" ]] || [[ $ACTUAL_CONTEXT == "cloud_okteto_com" ]]; then
    OKTETO_NAMESPACE=$($VKPR_KUBECTL config get-contexts --no-headers | grep "\*" | xargs | awk -F " " '{print $NF}')
    HELM_NAMESPACE=""
    YQ_VALUES="$YQ_VALUES |
      .ingress.enabled = \"false\" |
      .ingress.hosts[0].host = \"whoami-${OKTETO_NAMESPACE}.cloud.okteto.net\" |
      .service.annotations.[\"dev.okteto.com/auto-ingress\"] = \"true\"
    "
  fi
}