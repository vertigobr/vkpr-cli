#!/usr/bin/env bash
source "$(dirname "$0")"/unix/formula/objects.sh

runFormula() {
  local VKPR_ENV_OTEL_DOMAIN VKPR_OTEL_VALUES HELM_ARGS;
  [ $DRY_RUN = false ]
  formulaInputs

  VKPR_OTEL_VALUES=$(dirname "$0")/utils/otel.yaml
  VKPR_OTEL_COLETOR_JAEGER=$(dirname "$0")/utils/colector_jaeger.yaml
  VKPR_OTEL_COLETOR=$(dirname "$0")/utils/colector.yaml
  VKPR_INSTRUMENTATION=$(dirname "$0")/utils/instrumentation.yaml

  [ $DRY_RUN = false ]
  startInfos

  [ $DRY_RUN = false ] && registerHelmRepository opentelemetry-helm https://open-telemetry.github.io/opentelemetry-helm-charts
  installApplication "opentelemetry-operator" "opentelemetry-helm/opentelemetry-operator" "$VKPR_ENV_OTEL_NAMESPACE" "$VKPR_OTEL_VERSION" "$VKPR_OTEL_VALUES" "$HELM_ARGS"
  
  if [[ "$VKPR_ENV_TRACE" == jaeger ]]; then
  $VKPR_KUBECTL apply -f "$VKPR_OTEL_COLETOR_JAEGER" -n "$VKPR_ENV_OTEL_NAMESPACE"
  fi

  if [[ "$VKPR_ENV_TRACE" == tempo ]]; then
  $VKPR_KUBECTL apply -f "$VKPR_OTEL_COLETOR" -n "$VKPR_ENV_OTEL_NAMESPACE"
  fi 

  if [[ "$VKPR_ENV_OTEL_AUTO" == true ]]; then
  $VKPR_KUBECTL apply -f "$VKPR_INSTRUMENTATION" -n "$VKPR_ENV_INSTRUMENTATION_NAMESPACE"
  fi

}

startInfos() {
  bold "=============================="
  boldInfo "VKPR OTEL Install Routine"
  boldNotice "Secure: $VKPR_ENV_GLOBAL_SECURE"
  boldNotice "Namespace: $VKPR_ENV_OTEL_NAMESPACE"
  boldNotice "Trace: $VKPR_ENV_TRACE"
  boldNotice "Auto Instrumentation: $VKPR_ENV_OTEL_AUTO"
  boldNotice "Instrumentation Namespace: $VKPR_ENV_INSTRUMENTATION_NAMESPACE"
  bold "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "otel.namespace" "OTEL_NAMESPACE"
  checkGlobalConfig "$INSTRUMENTATION_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "otel.instrumentation" "INSTRUMENTATION_NAMESPACE"
  checkGlobalConfig "$OTEL_AUTO" "true" "otel.auto.enable" "OTEL_AUTO"
  checkGlobalConfig "$TRACE" "jaeger" "otel.trace" "TRACE"
}

settingOtelEnvironment() {
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    YQ_VALUES="$YQ_VALUES"
  fi
}


