#!/usr/bin/env bash

runFormula() {
  local VKPR_EXTERNAL_SECRETS_VALUES HELM_ARGS;
  formulaInputs
  validateInputs

  VKPR_EXTERNAL_SECRETS_VALUES=$(dirname "$0")/utils/external-secrets.yaml

  startInfos
  settingExternalSecrets
  [[ $DRY_RUN = false ]] && registerHelmRepository external-secrets-operator https://charts.external-secrets.io/

  $VKPR_YQ eval -i "$YQ_VALUES" "$VKPR_EXTERNAL_SECRETS_VALUES"

  cat "$VKPR_EXTERNAL_SECRETS_VALUES"
  installApplication "external-secrets" "external-secrets-operator/external-secrets" "$VKPR_ENV_EXTERNAL_SECRETS_NAMESPACE" "$VKPR_EXTERNAL_SECRETS_VERSION" "$VKPR_EXTERNAL_SECRETS_VALUES" "$HELM_ARGS"
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR External-Secrets Install Routine"
  bold "=============================="
}

formulaInputs() {
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "external-secrets.namespace" "EXTERNAL_SECRETS_NAMESPACE"
  checkGlobalConfig "false" "false" "external-secrets.metrics" "EXTERNAL_SECRETS_METRICS"

  # checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "GRAFANA_NAMESPACE"
}

validateInputs() {
  validateExternalSecretNamespace "$VKPR_ENV_EXTERNAL_SECRETS_NAMESPACE"
  validateExternalSecretMetrics "$VKPR_ENV_EXTERNAL_SECRETS_METRICS"
}

settingExternalSecrets() {
  YQ_VALUES=".installCRDs = true"

  # if [[ "$VKPR_ENV_EXTERNAL_SECRETS_METRICS" == "true" ]] && [[ $(checkPodName "$VKPR_ENV_GRAFANA_NAMESPACE" "prometheus-stack-grafana") == "true" ]]; then
  #   YQ_VALUES="$YQ_VALUES |
  #     .metrics.service.enabled = \"true\" |
  #     .serviceMonitor.enabled = \"true\" |
  #     .webhook.serviceMonitor.enabled = \"true\" |
  #     .certController.serviceMonitor.enabled = \"true\"
  #   "
  # fi
  settingExternalSecretsEnvironment
  debug "YQ_CONTENT = $YQ_VALUES"
}

settingExternalSecretsEnvironment() {
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    YQ_VALUES="$YQ_VALUES"
  fi
}