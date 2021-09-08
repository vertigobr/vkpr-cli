#!/bin/sh

runFormula() {
  echoColor "yellow" "Installing external-dns with powerdns..."
  VKPR_EXTERNAL_DNS_VALUES=$(dirname "$0")/utils/external-dns.yaml

  getProviderCreds
  add_repo_external_dns
  install_external_dns
}

add_repo_external_dns() {
  $VKPR_HOME/bin/helm repo add bitnami https://charts.bitnami.com/bitnami
  $VKPR_HOME/bin/helm repo update
}

install_external_dns() {
  $VKPR_HOME/bin/helm upgrade -i external-dns \
    --set pdns.apiKey=$APIKEY \
    --set pdns.apiUrl=$APIURL \
    -f $VKPR_EXTERNAL_DNS_VALUES bitnami/external-dns
}

getProviderCreds(){
  if [ -z "$APIKEY" ]; then
    echo "yellow" "No powerdns apikey found in rit credentials. Falling back to PDNS_APIKEY env variable."
    APIKEY="$PDNS_APIKEY"
  fi
  if [ -z "$APIKEY" ]; then
    echoColor "red" "No powerdns apikey found in both rit credentials or PDNS_APIKEY env variable."
    echoColor "red" "External-dns will fail to manage records unless you provide the powerdns apikey."
    echoColor "red" "Please check https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/pdns.md"
  fi
}
