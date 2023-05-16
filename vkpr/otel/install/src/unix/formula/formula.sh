#!/usr/bin/env bash
source "$(dirname "$0")"/unix/formula/objects.sh

runFormula() {
  local VKPR_ENV_OTEL_DOMAIN VKPR_OTEL_VALUES HELM_ARGS;
  [ $DRY_RUN = false ]
  formulaInputs

  VKPR_OTEL_VALUES=$(dirname "$0")/utils/otel.yaml
  VKPR_OTEL_COLETOR=$(dirname "$0")/utils/coletor.yaml
  VKPR_INSTRUMENTATION=$(dirname "$0")/utils/instrumentation.yaml
  [ $DRY_RUN = false ]
  startInfos

  [ $DRY_RUN = false ] && registerHelmRepository opentelemetry-helm https://open-telemetry.github.io/opentelemetry-helm-charts
  installApplication "opentelemetry-operator" "opentelemetry-helm/opentelemetry-operator" "$VKPR_ENV_OTEL_NAMESPACE" "$VKPR_OTEL_VERSION" "$VKPR_OTEL_VALUES" "$HELM_ARGS"
  $VKPR_KUBECTL apply -f "$VKPR_OTEL_COLETOR" -n "$VKPR_ENV_OTEL_NAMESPACE"

  if [[ "$VKPR_ENV_OTEL_AUTO" == true ]]; then
  $VKPR_KUBECTL apply -f "$VKPR_INSTRUMENTATION" -n "$VKPR_ENV_OTEL_NAMESPACE"
  fi

}

startInfos() {
  bold "=============================="
  boldInfo "VKPR OTEL Install Routine"
  boldNotice "Domain: $VKPR_ENV_OTEL_DOMAIN"
  boldNotice "Secure: $VKPR_ENV_GLOBAL_SECURE"
  boldNotice "Namespace: $VKPR_ENV_OTEL_NAMESPACE"
  boldNotice "Auto Instrumentation: $VKPR_ENV_OTEL_AUTO"
  bold "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "otel.namespace" "OTEL_NAMESPACE"
  checkGlobalConfig "$OTEL_AUTO" "true" "otel.auto.enable" "OTEL_AUTO"

}
settingOtelEnvironment() {
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    YQ_VALUES="$YQ_VALUES"
  fi
}
