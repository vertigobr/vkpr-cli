#!/bin/bash

runFormula() {
  # Global values
  checkGlobalConfig "$DOMAIN" "localhost" "global.domain" "GLOBAL_DOMAIN"
  checkGlobalConfig "$SECURE" "false" "global.secure" "GLOBAL_SECURE"
  checkGlobalConfig "nginx" "nginx" "global.ingressClassName" "GLOBAL_INGRESS"
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "global.namespace" "GLOBAL_NAMESPACE"
  checkGlobalConfig "" "" "global.provider" "GLOBAL_PROVIDER"

  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS" "$VKPR_ENV_GLOBAL_INGRESS" "whoami.ingressClassName" "WHOAMI_INGRESS"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "whoami.namespace" "WHOAMI_NAMESPACE"

  local VKPR_ENV_WHOAMI_DOMAIN="whoami.${VKPR_ENV_GLOBAL_DOMAIN}"
  local VKPR_WHOAMI_VALUES; VKPR_WHOAMI_VALUES=$(dirname "$0")/utils/whoami.yaml

  startInfos
  addRepoWhoami
  installWhoami
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Whoami Install Routine")"
  echoColor "bold" "$(echoColor "blue" "Whoami Domain:") ${VKPR_ENV_WHOAMI_DOMAIN}"
  echoColor "bold" "$(echoColor "blue" "Ingress Controller:") ${VKPR_ENV_WHOAMI_INGRESS}"
  echo "=============================="
}

addRepoWhoami() {
  registerHelmRepository cowboysysop https://cowboysysop.github.io/charts/
}

installWhoami() {
  echoColor "bold" "$(echoColor "green" "Installing whoami...")"
  local YQ_VALUES=".ingress.hosts[0].host = \"$VKPR_ENV_WHOAMI_DOMAIN\""
  local HELM_NAMESPACE="--create-namespace --namespace=$VKPR_ENV_WHOAMI_NAMESPACE"
  settingWhoami

  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_WHOAMI_VALUES" \
  | $VKPR_HELM upgrade -i --version "$VKPR_WHOAMI_VERSION" $HELM_NAMESPACE \
    --wait -f - whoami cowboysysop/whoami
}

settingWhoami() {
  YQ_VALUES="$YQ_VALUES |
    .ingress.annotations.[\"kubernetes.io/ingress.class\"] = \"$VKPR_ENV_WHOAMI_INGRESS\"
  "
  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .ingress.tls[0].hosts[0] = \"$VKPR_ENV_WHOAMI_DOMAIN\" |
      .ingress.tls[0].secretName = \"whoami-cert\"
    "
  fi

  settingWhoamiProvider
  mergeVkprValuesHelmArgs "whoami" "$VKPR_WHOAMI_VALUES"
}

settingWhoamiProvider() {
  ACTUAL_CONTEXT=$($VKPR_KUBECTL config get-contexts --no-headers | grep \* | xargs | awk -F " " '{print $2}')
  if [[ "$VKPR_ENV_GLOBAL_PROVIDER" == "okteto" ]] || [[ $ACTUAL_CONTEXT == "cloud_okteto_com" ]]; then
    OKTETO_NAMESPACE=$($VKPR_KUBECTL config get-contexts --no-headers | grep \* | xargs | awk -F " " '{print $NF}')
    HELM_NAMESPACE=""
    YQ_VALUES="$YQ_VALUES |
      .ingress.enabled = \"false\" |
      .ingress.hosts[0].host = \"whoami-${OKTETO_NAMESPACE}.cloud.okteto.net\" |
      .service.annotations.[\"dev.okteto.com/auto-ingress\"] = \"true\"
    "
  fi
}