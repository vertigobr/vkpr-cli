#!/usr/bin/env bash

source $(dirname "$0")/unix/formula/inputs.sh
source $(dirname "$0")/unix/formula/objects.sh
source $(dirname "$0")/unix/formula/settings.sh

startInfos() {
  bold "=============================="
  boldInfo "VKPR Whoami Install Routine"
  boldNotice "Domain: $VKPR_ENV_WHOAMI_DOMAIN"
  boldNotice "Secure: $VKPR_ENV_GLOBAL_SECURE"
  boldNotice "Namespace: $VKPR_ENV_WHOAMI_NAMESPACE"
  boldNotice "Ingress Controller: $VKPR_ENV_WHOAMI_INGRESS_CLASS_NAME"
  bold "=============================="
}

runFormula() {
  local VKPR_ENV_WHOAMI_DOMAIN VKPR_WHOAMI_VALUES HELM_ARGS;

  VKPR_ENV_WHOAMI_DOMAIN="whoami.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_WHOAMI_VALUES=$(dirname "$0")/utils/whoami.yaml

  formulaInputs
  validateInputs

  ! $VKPR_KUBECTL get ns | grep -q $VKPR_ENV_WHOAMI_NAMESPACE && $VKPR_KUBECTL create ns $VKPR_ENV_WHOAMI_NAMESPACE

  startInfos
  settingWhoami
  [ $DRY_RUN = false ] && registerHelmRepository cowboysysop https://cowboysysop.github.io/charts/
  installApplication "whoami" "cowboysysop/whoami" "$VKPR_ENV_WHOAMI_NAMESPACE" "$VKPR_WHOAMI_VERSION" "$VKPR_WHOAMI_VALUES" "$HELM_ARGS"
}
