#!/bin/bash

runFormula() {
  # Global values
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "global.namespace" "GLOBAL_NAMESPACE"

  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "external-dns.namespace" "EXTERNAL_DNS_NAMESPACE"
  checkGlobalConfig "false" "false" "external-dns.metrics" "EXTERNAL_DNS_METRICS"

  local VKPR_EXTERNAL_DNS_VALUES; VKPR_EXTERNAL_DNS_VALUES="$(dirname "$0")"/utils/external-dns.yaml

  startInfos
  addRepoExternalDNS
  installExternalDNS
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR External-DNS Install AWS Routine")"
  echo "=============================="
}

addRepoExternalDNS() {
  registerHelmRepository bitnami https://charts.bitnami.com/bitnami
}

installExternalDNS() {
  echoColor "bold" "$(echoColor "green" "Installing External-DNS AWS...")"
  local YQ_VALUES=".rbac.create = true"
  settingExternalDNS

  $VKPR_YQ eval -i "$YQ_VALUES" "$VKPR_EXTERNAL_DNS_VALUES"
  mergeVkprValuesHelmArgs "external-dns" "$VKPR_EXTERNAL_DNS_VALUES"
  $VKPR_HELM upgrade -i --version "$VKPR_EXTERNAL_DNS_VERSION" \
    --namespace "$VKPR_ENV_EXTERNAL_DNS_NAMESPACE" --create-namespace \
    --wait -f "$VKPR_EXTERNAL_DNS_VALUES" external-dns bitnami/external-dns
}


settingExternalDNS() {
  AWS_REGION=$($VKPR_JQ -r .credential.region ~/.rit/credentials/default/aws)
  AWS_ACCESS_KEY=$($VKPR_JQ -r .credential.accesskeyid ~/.rit/credentials/default/aws)
  AWS_SECRET_KEY=$($VKPR_JQ -r .credential.secretaccesskey ~/.rit/credentials/default/aws)

  validateAwsAccessKey "$AWS_ACCESS_KEY"
  validateAwsSecretKey "$AWS_SECRET_KEY"
  validateAwsRegion "$AWS_REGION"

  YQ_VALUES="$YQ_VALUES |
    .provider = \"aws\" |
    .aws.credentials.accessKey = \"$AWS_ACCESS_KEY\" |
    .aws.credentials.secretKey = \"$AWS_SECRET_KEY\" |
    .aws.region = \"$AWS_REGION\"
  "

  if [[ $VKPR_ENV_EXTERNAL_DNS_METRICS == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .metrics.enabled = \"true\" |
      .metrics.serviceMonitor.enabled = \"true\" |
      .metrics.serviceMonitor.namespace = \"$VKPR_ENV_INGRESS_NAMESPACE\" |
      .metrics.serviceMonitor.interval = \"1m\"
    "
  fi
}