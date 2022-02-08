#!/bin/sh

runFormula() {
  local VKPR_EXTERNAL_DNS_VALUES=$(dirname "$0")/utils/external-dns.yaml
  local RIT_CREDENTIALS_PATH=~/.rit/credentials/default
  [[ $PDNS_APIURL == "" ]] && PDNS_APIURL="example.com"

  checkGlobalConfig $PDNS_APIURL "example.com" "external-dns.powerDNS.apiUrl" "EXTERNAL_DNS_PDNS_APIURL"
  checkGlobalConfig "false" "false" "external-dns.metrics" "METRICS"

  startInfos
  addRepoExternalDNS
  installExternalDNS
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR External-DNS Install Routine")"
  echoColor "bold" "$(echoColor "blue" "Provider:") ${PROVIDER}"
  echo "=============================="
}

addRepoExternalDNS() {
  registerHelmRepository bitnami https://charts.bitnami.com/bitnami
}

installExternalDNS() {
  local YQ_VALUES='.rbac.create = true'
  if [[ ! -f $RIT_CREDENTIALS_PATH/$PROVIDER ]]; then
    echoColor "red" "Doesn't exists credential $PROVIDER to use in formula, create her or use the provider flag."
  else
    echoColor "bold" "$(echoColor "green" "Installing External-DNS...")"
    settingExternalDNS
    $VKPR_YQ eval "$YQ_VALUES" "$VKPR_EXTERNAL_DNS_VALUES" \
    | $VKPR_HELM upgrade -i --version "$VKPR_EXTERNAL_DNS_VERSION" \
      --create-namespace --namespace "$VKPR_K8S_NAMESPACE" \
      --wait -f - external-dns bitnami/external-dns
  fi
}


settingExternalDNS() {
  case $PROVIDER in
    aws)
        AWS_REGION=$(cat ~/.rit/credentials/default/aws | $VKPR_JQ -r .credential.region)
        AWS_ACCESS_KEY=$(cat ~/.rit/credentials/default/aws | $VKPR_JQ -r .credential.accesskeyid)
        AWS_SECRET_KEY=$(cat ~/.rit/credentials/default/aws | $VKPR_JQ -r .credential.secretaccesskey)
        validateAwsAccessKey $AWS_ACCESS_KEY
        validateAwsSecretKey $AWS_SECRET_KEY
        validateAwsRegion $AWS_REGION
        YQ_VALUES=''$YQ_VALUES' |
          .provider = "aws" |
          .aws.credentials.accessKey = "'$AWS_ACCESS_KEY'" |
          .aws.credentials.secretKey = "'$AWS_SECRET_KEY'" |
          .aws.region = "'$AWS_REGION'"
        '
      ;;
    digitalocean)
        DO_TOKEN=$(cat ~/.rit/credentials/default/digitalocean | $VKPR_JQ -r .credential.token)
        validateDigitalOceanApiToken $DO_TOKEN
        YQ_VALUES=''$YQ_VALUES' |
          .provider = "digitalocean" |
          .digitalocean.apiToken = "'$DO_TOKEN'"
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
  if [[ $VKPR_ENV_METRICS == "true" ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .metrics.enabled = true |
      .metrics.serviceMonitor.enabled = true |
      .metrics.serviceMonitor.namespace = "vkpr" |
      .metrics.serviceMonitor.interval = "1m"
    '
  fi

  mergeVkprValuesHelmArgs "external-dns" $VKPR_EXTERNAL_DNS_VALUES
}