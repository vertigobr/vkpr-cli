#!/bin/bash

runFormula() {
  local VKPR_EXTERNAL_DNS_VALUES YQ_VALUES HELM_ARGS;
  setCredentials
  formulaInputs
  validateInputs

  $VKPR_KUBECTL create ns $VKPR_ENV_EXTERNAL_DNS_NAMESPACE 2> /dev/null
  VKPR_EXTERNAL_DNS_VALUES="$(dirname "$0")"/utils/external-dns.yaml

  startInfos
  settingExternalDNS
  if [[ $DRY_RUN == false ]]; then
    registerHelmRepository external-dns https://kubernetes-sigs.github.io/external-dns/
    createDOCredentialSecret "$VKPR_ENV_EXTERNAL_DNS_NAMESPACE" "$DO_TOKEN"
  fi
  installApplication "external-dns" "external-dns/external-dns" "$VKPR_ENV_EXTERNAL_DNS_NAMESPACE" "$VKPR_EXTERNAL_DNS_VERSION" "$VKPR_EXTERNAL_DNS_VALUES" "$HELM_ARGS"
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR External-DNS Install Digital Ocean Routine"
  bold "=============================="
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
  YQ_VALUES=".domainFilters[0] = \"$VKPR_ENV_GLOBAL_DOMAIN\""

  if [[ $VKPR_ENV_EXTERNAL_DNS_METRICS == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .serviceMonitor.enabled = true |
      .serviceMonitor.namespace = \"$VKPR_ENV_INGRESS_NAMESPACE\" |
      .serviceMonitor.interval = \"1m\"
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
