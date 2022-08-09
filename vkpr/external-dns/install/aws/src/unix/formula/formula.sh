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
    createAWSCredentialSecret "$VKPR_ENV_EXTERNAL_DNS_NAMESPACE" "$AWS_ACCESS_KEY" "$AWS_SECRET_KEY" "$AWS_REGION"
  fi
  installApplication "external-dns" "external-dns/external-dns" "$VKPR_ENV_EXTERNAL_DNS_NAMESPACE" "$VKPR_EXTERNAL_DNS_VERSION" "$VKPR_EXTERNAL_DNS_VALUES" "$HELM_ARGS"
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR External-DNS Install AWS Routine"
  bold "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "external-dns.namespace" "EXTERNAL_DNS_NAMESPACE"
  checkGlobalConfig "false" "false" "external-dns.metrics" "EXTERNAL_DNS_METRICS"
}

setCredentials() {
  AWS_REGION=$($VKPR_JQ -r .credential.region "$VKPR_CREDENTIAL"/aws)
  AWS_ACCESS_KEY=$($VKPR_JQ -r .credential.accesskeyid "$VKPR_CREDENTIAL"/aws)
  AWS_SECRET_KEY=$($VKPR_JQ -r .credential.secretaccesskey "$VKPR_CREDENTIAL"/aws)
}

validateInputs() {
  validateExternalDNSDomain "$VKPR_ENV_GLOBAL_DOMAIN"
  validateExternalDNSNamespace "$VKPR_ENV_EXTERNAL_DNS_NAMESPACE"
  validateExternalDNSMetrics "$VKPR_ENV_EXTERNAL_DNS_METRICS"

  validateAwsAccessKey "$AWS_ACCESS_KEY"
  validateAwsSecretKey "$AWS_SECRET_KEY"
  validateAwsRegion "$AWS_REGION"
}

installCRDS() {
  info "Installing external-dns CRDS beforehand..."
  $VKPR_KUBECTL apply -f "https://raw.githubusercontent.com/kubernetes-sigs/external-dns/master/docs/contributing/crd-source/crd-manifest.yaml"
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
