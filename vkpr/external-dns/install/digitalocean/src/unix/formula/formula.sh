#!/usr/bin/env bash

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
    installCRDS
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

  # External apps values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "GRAFANA_NAMESPACE"
}

setCredentials() {
  DO_TOKEN=$($VKPR_JQ -r .credential.token "$VKPR_CREDENTIAL"/digitalocean)
}

validateInputs() {
  validateExternalDNSDomain "$VKPR_ENV_GLOBAL_DOMAIN"
  validateExternalDNSNamespace "$VKPR_ENV_EXTERNAL_DNS_NAMESPACE"
  validateExternalDNSMetrics "$VKPR_ENV_EXTERNAL_DNS_METRICS"

  validateDigitalOceanApiToken "$DO_TOKEN"
}

installCRDS() {
  info "Installing external-dns CRDS beforehand..."
  $VKPR_KUBECTL apply -f "https://raw.githubusercontent.com/kubernetes-sigs/external-dns/master/docs/contributing/crd-source/crd-manifest.yaml"
}

settingExternalDNS() {
  YQ_VALUES=".domainFilters[0] = \"$VKPR_ENV_GLOBAL_DOMAIN\""

  if [[ $VKPR_ENV_EXTERNAL_DNS_METRICS == true ]] && [[ $(checkPodName "$VKPR_ENV_GRAFANA_NAMESPACE" "prometheus-stack-grafana") == "true" ]]; then
    createGrafanaDashboard "$(dirname "$0")/utils/dashboard.json" "$VKPR_ENV_GRAFANA_NAMESPACE"
    YQ_VALUES="$YQ_VALUES |
      .serviceMonitor.enabled = true |
      .serviceMonitor.namespace = \"$VKPR_ENV_EXTERNAL_DNS_NAMESPACE\" |
      .serviceMonitor.interval = \"1m\" |
      .serviceMonitor.additionalLabels.release = \"prometheus-stack\"
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
