#!/bin/bash

runFormula() {
  local VKPR_EXTERNAL_DNS_VALUES YQ_VALUES HELM_ARGS;
  setCredentials
  formulaInputs
  validateInputs

  VKPR_EXTERNAL_DNS_VALUES="$(dirname "$0")"/utils/external-dns.yaml

  startInfos
  settingExternalDNS
  [[ $DRY_RUN == false ]] && registerHelmRepository bitnami https://charts.bitnami.com/bitnami
  installApplication "external-dns" "bitnami/external-dns" "$VKPR_ENV_EXTERNAL_DNS_NAMESPACE" "$VKPR_EXTERNAL_DNS_VERSION" "$VKPR_EXTERNAL_DNS_VALUES" "$HELM_ARGS"
}

startInfos() {
  echo "=============================="
  bold "$(info "VKPR External-DNS Install Digital Ocean Routine")"
  echo "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "external-dns.namespace" "EXTERNAL_DNS_NAMESPACE"
  checkGlobalConfig "false" "false" "external-dns.metrics" "EXTERNAL_DNS_METRICS"
}

setCredentials() {
  DO_TOKEN=$($VKPR_JQ -r .credential.token "$VKPR_CREDENTIAL"/digitalocean)
}

validateInputs() {
  validateDigitalOceanApiToken "$DO_TOKEN"
}

settingExternalDNS() {
  YQ_VALUES=".provider = \"digitalocean\" |
    .rbac.create = true |
    .digitalocean.apiToken = \"$DO_TOKEN\"
  "

  if [[ $VKPR_ENV_EXTERNAL_DNS_METRICS == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .metrics.enabled = true |
      .metrics.serviceMonitor.enabled = true |
      .metrics.serviceMonitor.namespace = \"$VKPR_ENV_INGRESS_NAMESPACE\" |
      .metrics.serviceMonitor.interval = \"1m\"
    "
  fi
  settingExternaldnsEnvironment

  debug "YQ_CONTENT = $YQ_VALUES"
}

settingExternaldnsEnvironment() {
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    YQ_VALUES="$YQ_VALUES"
  fi
}