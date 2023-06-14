#!/usr/bin/env bash

runFormula() {
  [[ ! -f "$PATH_TO_FILE" ]] && error "Wrong file" && exit
  cp "$PATH_TO_FILE" "$(dirname "$0")"
  VKPR_GLOBAL_CONFIG="$(dirname "$0")"/vkpr.yaml

  #Check global.provider and configure rit credentials
  local GLOBAL_PROVIDER_EXISTS;
  GLOBAL_PROVIDER_EXISTS=$($VKPR_YQ eval ".global | has(\"provider\")" "$VKPR_GLOBAL_CONFIG")
  if [ "$GLOBAL_PROVIDER_EXISTS" == true ];then
    local GLOBAL_PROVIDER; GLOBAL_PROVIDER=$($VKPR_YQ eval .global.provider "$VKPR_GLOBAL_CONFIG")
    configureProvider "$GLOBAL_PROVIDER"
  fi
  planConfig
}

planConfig(){
export VKPR_PLAN=true

  installLoki
  installPrometheusGrafana
  installPostgresql
  installExternalDNS
  installCertManager
  installKong
  installIngress
  installConsul
  installVault
  installKeycloak
  installArgoCD
  installWhoami
  installJaeger
  installMockserver
  installDevportal


  echo "==================================================================" >> /tmp/diff.txt
  echo "            type :q and press enter to exit" >> /tmp/diff.txt
  echo "==================================================================" >> /tmp/diff.txt
  vi -R /tmp/diff.txt
  rm /tmp/diff.txt
  unset VKPR_PLAN 
}

installArgoCD(){
  ARGO_EXISTS=$($VKPR_YQ eval .argocd.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$ARGO_EXISTS" == true ]; then
    rit vkpr argocd install --diff 
  fi
}

installCertManager(){
  CERT_MANAGER_EXISTS=$($VKPR_YQ eval .cert-manager.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$CERT_MANAGER_EXISTS" == true ]; then
    case $GLOBAL_PROVIDER in
        aws)
          local CERT_MANAGER_HOSTEDZONE; CERT_MANAGER_HOSTEDZONE=$($VKPR_YQ eval .cert-manager.hostedZoneID "$VKPR_GLOBAL_CONFIG")
          rit vkpr cert-manager install aws --aws_hostedzone_id="$CERT_MANAGER_HOSTEDZONE" --diff
        ;;
        digitalocean)
          rit vkpr cert-manager install digitalocean --diff
        ;;
      esac
  fi
}

installConsul(){
  CONSUL_EXISTS=$($VKPR_YQ eval .consul.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$CONSUL_EXISTS" == true ]; then
    rit vkpr consul install --diff
  fi
}

installDevportal(){
  DEVPORTAL_EXISTS=$($VKPR_YQ eval .devportal.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$DEVPORTAL_EXISTS" == true ]; then
    rit vkpr devportal install --diff
  fi
}

installExternalDNS(){
  EXTERNAL_DNS_EXISTS=$($VKPR_YQ eval .external-dns.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$EXTERNAL_DNS_EXISTS" == true ]; then
    rit vkpr external-dns install "$GLOBAL_PROVIDER" --diff
  fi
}

installIngress(){
  INGRESS_EXISTS=$($VKPR_YQ eval .ingress.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$INGRESS_EXISTS" == true ]; then
    rit vkpr ingress install --diff
  fi
}

installJaeger(){
  JAEGER_EXISTS=$($VKPR_YQ eval .jaeger.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$JAEGER_EXISTS" == true ]; then
    rit vkpr jaeger install --diff
  fi
}

installKeycloak(){
  KEYCLOAK_EXISTS=$($VKPR_YQ eval .keycloak.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$KEYCLOAK_EXISTS" == true ]; then
    rit vkpr keycloak install --diff
  fi
}

installKong(){
  KONG_EXISTS=$($VKPR_YQ eval .kong.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$KONG_EXISTS" == true ]; then
    rit vkpr kong install --diff 
  fi
}

installLoki(){
  LOKI_EXISTS=$($VKPR_YQ eval .loki.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$LOKI_EXISTS" == true ]; then
    rit vkpr loki install --diff
  fi
}

installMockserver(){
  MOCKSERVER_EXISTS=$($VKPR_YQ eval .mockserver.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$MOCKSERVER_EXISTS" == true ]; then
    rit vkpr mockserver install --diff
  fi
}

installPostgresql(){
  POSTGRES_EXISTS=$($VKPR_YQ eval .postgresql.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$POSTGRES_EXISTS" == true ]; then
    rit vkpr postgresql install --diff
  fi
}

installPrometheusGrafana(){
  PROMETHEUS_STACK_EXISTS=$($VKPR_YQ eval .prometheus-stack.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$PROMETHEUS_STACK_EXISTS" == true ]; then
    rit vkpr prometheus-stack install --diff
  fi
}

installVault(){
  VAULT_EXISTS=$($VKPR_YQ eval .vault.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$VAULT_EXISTS" == true ]; then
    rit vkpr vault install --diff
  fi
}

installWhoami(){
  WHOAMI_EXISTS=$($VKPR_YQ eval .whoami.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$WHOAMI_EXISTS" == true ]; then
    rit vkpr whoami install --diff
  fi
}

configureProvider (){
  local PROVIDER;
  PROVIDER=$1
  case $PROVIDER in
      aws)
        CREDENTIALS_AWS_EXISTS=$($VKPR_YQ eval ".credentials | has(\"aws\")" "$VKPR_GLOBAL_CONFIG")
        if [ "$CREDENTIALS_AWS_EXISTS" == true ]; then
          local ACCESS_KEY SECRET_KEY REGION
          ACCESS_KEY=$($VKPR_YQ eval .credentials.aws.accessKey "$VKPR_GLOBAL_CONFIG")
          SECRET_KEY=$($VKPR_YQ eval .credentials.aws.secretKey "$VKPR_GLOBAL_CONFIG")
          REGION=$($VKPR_YQ eval .credentials.aws.region "$VKPR_GLOBAL_CONFIG")
          HOSTEDZONE=$($VKPR_YQ eval .cert-manager.aws.hostedZoneID "$VKPR_GLOBAL_CONFIG")
          rit set credential --provider="aws" \
            --fields="accesskeyid,secretaccesskey,region" \
            --values="$ACCESS_KEY,$SECRET_KEY,$REGION"
        fi
      ;;
      digitalocean)
        CREDENTIALS_DO_EXISTS=$($VKPR_YQ eval ".credentials | has(\"digitalocean\")" "$VKPR_GLOBAL_CONFIG")
        if [ "$CREDENTIALS_DO_EXISTS" == true ]; then
          local API_TOKEN; API_TOKEN=$($VKPR_YQ eval .credentials.digitalocean.apiToken "$VKPR_GLOBAL_CONFIG")
          rit set credential --provider="digitalocean" --fields="token" --values="$API_TOKEN"
        fi
      ;;
    esac
}