#!/bin/sh

runFormula() {
  local VKPR_EXTERNAL_DNS_VALUES=$(dirname "$0")/utils/external-dns.yaml
  local RIT_CREDENTIALS_PATH=~/.rit/credentials/default
  [[ $PDNS_APIURL == "" ]] && PDNS_APIURL="example.com"

  checkGlobalConfig $PROVIDER "aws" "external-dns.provider" "EXTERNAL_DNS_PROVIDER"
  checkGlobalConfig $PDNS_APIURL "example.com" "external-dns.powerDNS.apiUrl" "EXTERNAL_DNS_PDNS_APIURL"
  checkGlobal "external-dns.resources" $VKPR_EXTERNAL_DNS_VALUES "resources"
  checkGlobal "external-dns.extraEnv" $VKPR_EXTERNAL_DNS_VALUES

  startInfos
  addRepoExternalDNS
  installExternalDNS
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR External-DNS Install Routine")"
  echoColor "bold" "$(echoColor "blue" "Provider:") ${VKPR_ENV_EXTERNAL_DNS_PROVIDER}"
  echo "=============================="
}

addRepoExternalDNS() {
  $VKPR_HELM repo add bitnami https://charts.bitnami.com/bitnami --force-update
}

installExternalDNS() {
  local YQ_VALUES='.rbac.create = true'
  if [[ ! -f $RIT_CREDENTIALS_PATH/$VKPR_ENV_EXTERNAL_DNS_PROVIDER ]]; then
    echoColor "red" "Doesn't exists credential $VKPR_ENV_EXTERNAL_DNS_PROVIDER to use in formula, create her or use the provider flag."
  else
    settingExternalDNS
    $VKPR_YQ eval "$YQ_VALUES" "$VKPR_EXTERNAL_DNS_VALUES" \
    | $VKPR_HELM upgrade -i --version "$VKPR_EXTERNAL_DNS_VERSION" \
      --create-namespace --namespace "$VKPR_K8S_NAMESPACE" \
      --wait -f - external-dns bitnami/external-dns
  fi
}


settingExternalDNS() {
  case $VKPR_ENV_EXTERNAL_DNS_PROVIDER in
    aws)
        YQ_VALUES=''$YQ_VALUES' |
          .provider = "aws" |
          .aws.credentials.accessKey = "'$($VKPR_JQ -r .credential.accesskeyid $RIT_CREDENTIALS_PATH/aws)'" |
          .aws.credentials.secretKey = "'$($VKPR_JQ -r .credential.secretaccesskey $RIT_CREDENTIALS_PATH/aws)'" |
          .aws.region = "'$($VKPR_JQ -r .credential.region $RIT_CREDENTIALS_PATH/aws)'"
        '
      ;;
    digitalocean)
        YQ_VALUES=''$YQ_VALUES' |
          .provider = "digitalocean" |
          .digitalocean.apiToken = "'$($VKPR_JQ -r .credential.token $RIT_CREDENTIALS_PATH/digitalocean)'"
        '
      ;;
    powerDNS)
        YQ_VALUES=''$YQ_VALUES' |
          .provider = "pdns" |
          .pdns.apiUrl = "'$VKPR_ENV_EXTERNAL_DNS_PDNS_APIURL'" |
          .pdns.apiKey = "'$($VKPR_JQ -r .credential.apikey $RIT_CREDENTIALS_PATH/powerDNS)'" |
          .pdns.apiPort = "8081"
        '
      ;;
  esac
  if [[ $(checkPodName "prometheus-prometheus-stack-kube-prom-prometheus") == "true" ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .metrics.enabled = true |
      .metrics.serviceMonitor.enabled = true |
      .metrics.serviceMonitor.namespace = "vkpr" |
      .metrics.serviceMonitor.interval = "1m"
    '
  fi
}