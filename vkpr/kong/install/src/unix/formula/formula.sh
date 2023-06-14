#!/usr/bin/env bash

source "$(dirname "$0")"/unix/formula/inputs.sh
source "$(dirname "$0")"/unix/formula/objects.sh


runFormula() {
  local VKPR_KONG_VALUES KONG_NAMESPACE YQ_VALUES HELM_ARGS;
  formulaInputs
  validateInputs

  [[ "$VKPR_ENVIRONMENT" != "okteto" ]] && $VKPR_KUBECTL create ns "$VKPR_ENV_KONG_NAMESPACE" 2> /dev/null

  startInfos
  if [[ $DRY_RUN == false ]]; then
    registerHelmRepository kong https://charts.konghq.com
  fi
  settingKong
  installKong

  [[ $DRY_RUN == false ]] && [[ $DIFF == false ]] && [[ "$VKPR_ENVIRONMENT" != "okteto" ]] && installPlugins || true
  [[ $DRY_RUN == false ]] && [[ $DIFF == false ]] && checkComands
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Kong Install Routine"
  boldNotice "Domain: $VKPR_ENV_GLOBAL_DOMAIN"
  boldNotice "Secure: $VKPR_ENV_GLOBAL_SECURE"
  boldNotice "Namespace: $VKPR_ENV_KONG_NAMESPACE"
  boldNotice "HA: $VKPR_ENV_KONG_HA"
  boldNotice "Deploy Mode: ${VKPR_ENV_KONG_MODE}"
  bold "=============================="
}

installDB(){
  if [[ $(checkPodName "$VKPR_ENV_POSTGRESQL_NAMESPACE" "postgres-postgresql") != "true" ]]; then
    info "Initializing postgresql to Kong"
    [[ -f $CURRENT_PWD/vkpr.yaml ]] && cp "$CURRENT_PWD"/vkpr.yaml "$(dirname "$0")"
    rit vkpr postgresql install --HA=$VKPR_ENV_KONG_HA --default
  else
    info "Initializing Kong with Postgres already created"
  fi
}

settingKong() {
  case $VKPR_ENV_KONG_MODE in
    dbless)
      source "$(dirname "$0")"/unix/formula/setting/kong-dbless.sh
      VKPR_KONG_VALUES="$(dirname "$0")"/utils/kong-dbless.yaml
      ;;
    standard)
      source "$(dirname "$0")"/unix/formula/setting/kong-standard.sh
      VKPR_KONG_VALUES="$(dirname "$0")"/utils/kong.yaml
      ;;
    hybrid)
      if [[ "$KONG_PLANE" == "data" ]]; then
        source "$(dirname "$0")"/unix/formula/setting/kong-dp.sh
        VKPR_KONG_VALUES="$(dirname "$0")"/utils/kong-dp.yaml
      else
        source "$(dirname "$0")"/unix/formula/setting/kong-cp.sh
        VKPR_KONG_VALUES="$(dirname "$0")"/utils/kong-cp.yaml
      fi
      ;;
    esac
}

installKong() {
  if [[ "$VKPR_ENV_KONG_MODE" == "hybrid" ]] && [[ "$KONG_PLANE" == "data" ]]; then
    installApplication "kong-dp" "kong/kong" "$VKPR_ENV_KONG_NAMESPACE" "$VKPR_KONG_VERSION" "$VKPR_KONG_VALUES" "$HELM_ARGS"
    exit
  fi

  installApplication "kong" "kong/kong" "$VKPR_ENV_KONG_NAMESPACE" "$VKPR_KONG_VERSION" "$VKPR_KONG_VALUES" "$HELM_ARGS"
}

installPlugins() {
  if [[ "$VKPR_ENV_KONG_MODE" == "dbless" ]]; then
    $VKPR_KUBECTL apply -n $VKPR_ENV_KONG_NAMESPACE -f "$(dirname "$0")"/utils/kong-plugin-basicauth.yaml
  fi
  if [[ "$VKPR_ENV_KONG_METRICS" == "true" ]]; then
    $VKPR_KUBECTL apply -n $VKPR_ENV_KONG_NAMESPACE -f "$(dirname "$0")"/utils/kong-plugin-prometheus.yaml
  fi
}