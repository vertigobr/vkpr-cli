#!/bin/bash

runFormula() {
  # Global values
  checkGlobalConfig "$DOMAIN" "localhost" "global.domain" "GLOBAL_DOMAIN"
  checkGlobalConfig "$SECURE" "false" "global.secure" "GLOBAL_SECURE"
  checkGlobalConfig "nginx" "nginx" "global.ingressClassName" "GLOBAL_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "global.namespace" "GLOBAL_NAMESPACE"

  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "whoami.ingressClassName" "WHOAMI_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "whoami.namespace" "WHOAMI_NAMESPACE"

  local VKPR_ENV_WHOAMI_DOMAIN="whoami.${VKPR_ENV_GLOBAL_DOMAIN}"
  local VKPR_WHOAMI_VALUES; VKPR_WHOAMI_VALUES=$(dirname "$0")/utils/whoami.yaml

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
    echoColor "bold" "---"
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