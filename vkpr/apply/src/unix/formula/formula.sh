#!/bin/bash

runFormula() {
  [[ ! -f "$PATH_TO_FILE" ]] && error "Wrong file" && exit
  cp "$PATH_TO_FILE" "$(dirname "$0")"
  VKPR_GLOBAL_CONFIG="$(dirname "$0")"/vkpr.yaml

  applyConfig
}

applyConfig(){
#Order matters in this part!
#0
  infraUp

#1
  installLoki

#2
  installPrometheusGrafana

#3
  installPostgres

#4
  installKong

#5
  installIngress

#6
  installExternalDNS

#7
  installCertManager

#8
  installConsul

#9
  installVault

#10
  installKeycloak

#11
  installArgoCD

#12
  installWhoami

#13
  installJaeger

#14
  installMockserver

#15
  installDevportal
}

installArgoCD(){
  ARGO_EXISTS=$($VKPR_YQ eval .argocd.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$ARGO_EXISTS" == true ]; then
    rit vkpr argocd install --default
  fi
}

installCertManager(){
  CERT_MANAGER_EXISTS=$($VKPR_YQ eval .cert-manager.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$CERT_MANAGER_EXISTS" == true ]; then
    local CERT_MANAGER_PROVIDER CERT_MANAGER_SOLVER
    CERT_MANAGER_PROVIDER=$($VKPR_YQ eval .global.provider "$VKPR_GLOBAL_CONFIG")
    case $CERT_MANAGER_PROVIDER in
      aws)
        CREDENTIALS_AWS_EXISTS=$($VKPR_YQ eval ".credentials | has(\"aws\")" "$VKPR_GLOBAL_CONFIG")
        if [ "$CREDENTIALS_AWS_EXISTS" == true ]; then
          local CERT_MANAGER_ACCESS_KEY CERT_MANAGER_SECRET_KEY CERT_MANAGER_REGION
          CERT_MANAGER_ACCESS_KEY=$($VKPR_YQ eval .credential.aws.accessKey "$VKPR_GLOBAL_CONFIG")
          CERT_MANAGER_SECRET_KEY=$($VKPR_YQ eval .credential.aws.secretKey "$VKPR_GLOBAL_CONFIG")
          CERT_MANAGER_REGION=$($VKPR_YQ eval .credential.aws.region "$VKPR_GLOBAL_CONFIG")
          CERT_MANAGER_HOSTEDZONE=$($VKPR_YQ eval .cert-manager.aws.hostedZoneID "$VKPR_GLOBAL_CONFIG")
          rit set credential --provider="aws" \
            --fields="accesskeyid,secretaccesskey,region" \
            --values="$CERT_MANAGER_ACCESS_KEY,$CERT_MANAGER_SECRET_KEY,$CERT_MANAGER_REGION"
        fi
        rit vkpr cert-manager install aws --aws_hostedzone_id="$CERT_MANAGER_HOSTEDZONE" --default
        ;;
      digitalocean)
        CREDENTIALS_DO_EXISTS=$($VKPR_YQ eval ".credentials | has(\"digitalocean\")" "$VKPR_GLOBAL_CONFIG")
        if [ "$CREDENTIALS_DO_EXISTS" == true ]; then
          local CERT_MANAGER_API_TOKEN; CERT_MANAGER_API_TOKEN=$($VKPR_YQ eval .credential.digitalocean.apiToken "$VKPR_GLOBAL_CONFIG")
          rit set credential --provider="digitalocean" --fields="token" --values="$CERT_MANAGER_API_TOKEN"
        fi
        rit vkpr cert-manager install digitalocean --default
        ;;
    esac
  fi
}

installConsul(){
  CONSUL_EXISTS=$($VKPR_YQ eval .consul.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$CONSUL_EXISTS" == true ]; then
    rit vkpr consul install --default
  fi
}

installDevportal(){
  DEVPORTAL_EXISTS=$($VKPR_YQ eval .devportal.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$DEVPORTAL_EXISTS" == true ]; then
    rit vkpr devportal install --default
  fi
}

installExternalDNS(){
  EXTERNAL_DNS_EXISTS=$($VKPR_YQ eval .external-dns.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$EXTERNAL_DNS_EXISTS" == true ]; then
    local EXTERNAL_DNS_PROVIDER; EXTERNAL_DNS_PROVIDER=$($VKPR_YQ eval .global.provider "$VKPR_GLOBAL_CONFIG")
    case $EXTERNAL_DNS_PROVIDER in
      aws)
        CREDENTIALS_AWS_EXISTS=$($VKPR_YQ eval ".credentials | has(\"aws\")" "$VKPR_GLOBAL_CONFIG")
        if [ "$CREDENTIALS_AWS_EXISTS" == true ]; then
          local EXTERNAL_DNS_ACCESS_KEY EXTERNAL_DNS_SECRET_KEY EXTERNAL_DNS_REGION
          EXTERNAL_DNS_ACCESS_KEY=$($VKPR_YQ eval .credential.aws.accessKey "$VKPR_GLOBAL_CONFIG")
          EXTERNAL_DNS_SECRET_KEY=$($VKPR_YQ eval .credential.aws.secretKey "$VKPR_GLOBAL_CONFIG")
          EXTERNAL_DNS_REGION=$($VKPR_YQ eval .credential.aws.region "$VKPR_GLOBAL_CONFIG")
          rit set credential --provider="aws" \
            --fields="accesskeyid,secretaccesskey,region" \
            --values="$EXTERNAL_DNS_ACCESS_KEY,$EXTERNAL_DNS_SECRET_KEY,$EXTERNAL_DNS_REGION"
        fi
        rit vkpr external-dns install aws
        ;;
      digitalocean)
        CREDENTIALS_DO_EXISTS=$($VKPR_YQ eval ".credentials | has(\"digitalocean\")" "$VKPR_GLOBAL_CONFIG")
        if [ "$CREDENTIALS_DO_EXISTS" == true ]; then
          local EXTERNAL_DNS_API_TOKEN; EXTERNAL_DNS_API_TOKEN=$($VKPR_YQ eval .credential.digitalocean.apiToken "$VKPR_GLOBAL_CONFIG")
          rit set credential --provider="digitalocean" --fields="token" --values="$EXTERNAL_DNS_API_TOKEN"
        fi
        rit vkpr external-dns install digitalocean
        ;;
    esac
  fi
}

infraUp(){
  INFRA_EXISTS=$($VKPR_YQ eval .infra.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$INFRA_EXISTS" == true ]; then
    rit vkpr infra start --default
  fi
}

installIngress(){
  INGRESS_EXISTS=$($VKPR_YQ eval .ingress.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$INGRESS_EXISTS" == true ]; then
    rit vkpr ingress install --default
  fi
}

installJaeger(){
  JAEGER_EXISTS=$($VKPR_YQ eval .jaeger.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$JAEGER_EXISTS" == true ]; then
    rit vkpr jaeger install --default
  fi
}

installKeycloak(){
  KEYCLOAK_EXISTS=$($VKPR_YQ eval .keycloak.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$KEYCLOAK_EXISTS" == true ]; then
    rit vkpr keycloak install --default
  fi
}

installKong(){
  KONG_EXISTS=$($VKPR_YQ eval .kong.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$KONG_EXISTS" == true ]; then
    rit vkpr kong install --default
  fi
}

installLoki(){
  LOKI_EXISTS=$($VKPR_YQ eval .loki.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$LOKI_EXISTS" == true ]; then
    rit vkpr loki install --default
  fi
}

installMockserver(){
  MOCKSERVER_EXISTS=$($VKPR_YQ eval .mockserver.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$MOCKSERVER_EXISTS" == true ]; then
    rit vkpr mockserver install --default
  fi
}

installPostgres(){
  POSTGRES_EXISTS=$($VKPR_YQ eval .postgresql.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$POSTGRES_EXISTS" == true ]; then
    rit vkpr postgres install --default
  fi
}

installPrometheusGrafana(){
  PROMETHEUS_STACK_EXISTS=$($VKPR_YQ eval .prometheus-stack.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$PROMETHEUS_STACK_EXISTS" == true ]; then
    rit vkpr prometheus-stack install --default
  fi
}

installVault(){
  VAULT_EXISTS=$($VKPR_YQ eval .vault.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$VAULT_EXISTS" == true ]; then
    rit vkpr vault install --default
  fi
}

installWhoami(){
  WHOAMI_EXISTS=$($VKPR_YQ eval .whoami.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$WHOAMI_EXISTS" == true ]; then
    rit vkpr whoami install --default
  fi
}
