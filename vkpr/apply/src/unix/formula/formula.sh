#!/bin/bash

  runFormula() {
  [[ ! -f "$PATH_TO_FILE" ]] && echoColor "red" "Wrong file" && exit
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
}

installArgoCD(){
  ARGO_EXISTS=$($VKPR_YQ eval .global.argocd.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$ARGO_EXISTS" == true ]; then
    rit vkpr argocd install --default
  fi
}

installCertManager(){
  CERT_MANAGER_EXISTS=$($VKPR_YQ eval .global.cert-manager.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$CERT_MANAGER_EXISTS" == true ]; then
    local CERT_MANAGER_PROVIDER CERT_MANAGER_SOLVER 
    CERT_MANAGER_PROVIDER=$($VKPR_YQ eval .global.cert-manager.provider "$VKPR_GLOBAL_CONFIG")
    CERT_MANAGER_SOLVER=$($VKPR_YQ eval .global.cert-manager.solver "$VKPR_GLOBAL_CONFIG")
    [[ $CERT_MANAGER_SOLVER = "HTTP01" ]] && CERT_MANAGER_PROVIDER=""
    local AVAILABLE_CERT_MANAGER_HOSTEDZONE=""
    case $CERT_MANAGER_PROVIDER in
      aws)
        local CERT_MANAGER_ACCESS_KEY CERT_MANAGER_SECRET_KEY CERT_MANAGER_REGION AVAILABLE_CERT_MANAGER_HOSTEDZONE
        CERT_MANAGER_ACCESS_KEY=$($VKPR_YQ eval .global.cert-manager.aws.accessKey "$VKPR_GLOBAL_CONFIG")
        CERT_MANAGER_SECRET_KEY=$($VKPR_YQ eval .global.cert-manager.aws.secretKey "$VKPR_GLOBAL_CONFIG")
        CERT_MANAGER_REGION=$($VKPR_YQ eval .global.cert-manager.aws.region "$VKPR_GLOBAL_CONFIG")
        AVAILABLE_CERT_MANAGER_HOSTEDZONE="--cloud_provider aws --aws_hostedzone_id=$($VKPR_YQ eval .global.cert-manager.aws.hostedZoneID "$VKPR_GLOBAL_CONFIG")"

        rit set credential --provider="aws" \
          --fields="accesskeyid,secretaccesskey,region" \
          --values="$CERT_MANAGER_ACCESS_KEY,$CERT_MANAGER_SECRET_KEY,$CERT_MANAGER_REGION"
        ;;
      digitalocean)
        local CERT_MANAGER_API_TOKEN
        CERT_MANAGER_API_TOKEN=$($VKPR_YQ eval .global.cert-manager.digitalocean.apiToken "$VKPR_GLOBAL_CONFIG")
        rit set credential --provider="digitalocean" --fields="token" --values="$CERT_MANAGER_API_TOKEN"
        ;;
    esac

    rit vkpr cert-manager install --issuer_solver "$CERT_MANAGER_SOLVER" "$AVAILABLE_CERT_MANAGER_HOSTEDZONE" --default
  fi
}

installConsul(){
  CONSUL_EXISTS=$($VKPR_YQ eval .global.consul.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$CONSUL_EXISTS" == true ]; then
    rit vkpr consul install --default
  fi
}

installExternalDNS(){
  EXTERNAL_DNS_EXISTS=$($VKPR_YQ eval .global.external-dns.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$EXTERNAL_DNS_EXISTS" == true ]; then
    local EXTERNAL_DNS_PROVIDER; EXTERNAL_DNS_PROVIDER=$($VKPR_YQ eval .global.external-dns.provider "$VKPR_GLOBAL_CONFIG")
    case $EXTERNAL_DNS_PROVIDER in
      aws)
        local EXTERNAL_DNS_ACCESS_KEY EXTERNAL_DNS_SECRET_KEY EXTERNAL_DNS_REGION
        EXTERNAL_DNS_ACCESS_KEY=$($VKPR_YQ eval .global.external-dns.aws.accessKey "$VKPR_GLOBAL_CONFIG")
        EXTERNAL_DNS_SECRET_KEY=$($VKPR_YQ eval .global.external-dns.aws.secretKey "$VKPR_GLOBAL_CONFIG")
        EXTERNAL_DNS_REGION=$($VKPR_YQ eval .global.external-dns.aws.region "$VKPR_GLOBAL_CONFIG")

        rit set credential --provider="aws" \
          --fields="accesskeyid,secretaccesskey,region" \
          --values="$EXTERNAL_DNS_ACCESS_KEY,$EXTERNAL_DNS_SECRET_KEY,$EXTERNAL_DNS_REGION"
        ;;
      digitalocean)
        local EXTERNAL_DNS_API_TOKEN; EXTERNAL_DNS_API_TOKEN=$($VKPR_YQ eval .global.external-dns.digitalocean.apiToken "$VKPR_GLOBAL_CONFIG")

        rit set credential --provider="digitalocean" --fields="token" --values="$EXTERNAL_DNS_API_TOKEN"
        ;;
      powerDNS)
        local EXTERNAL_DNS_API_TOKEN; EXTERNAL_DNS_API_TOKEN=$($VKPR_YQ eval .global.external-dns.powerDNS.apiKey "$VKPR_GLOBAL_CONFIG")

        rit set credential --provider="powerDNS" --fields="apikey" --values="$EXTERNAL_DNS_API_TOKEN"
        ;;
    esac

    rit vkpr external-dns install --provider "$EXTERNAL_DNS_PROVIDER" --default
  fi
}

infraUp(){
  INFRA_EXISTS=$($VKPR_YQ eval .global.infra.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$INFRA_EXISTS" == true ]; then
    rit vkpr infra start --default
  fi
}

installIngress(){
  INGRESS_EXISTS=$($VKPR_YQ eval .global.ingress.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$INGRESS_EXISTS" == true ]; then
    rit vkpr ingress install --default
  fi
}

installKeycloak(){
  KEYCLOAK_EXISTS=$($VKPR_YQ eval .global.keycloak.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$KEYCLOAK_EXISTS" == true ]; then
    rit vkpr keycloak install --default
  fi
}

installKong(){
  KONG_EXISTS=$($VKPR_YQ eval .global.kong.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$KONG_EXISTS" == true ]; then
    local KONG_ENTERPRISE="" \
      KONG_ENTERPRISE_LICENSE=""

    if [[ $($VKPR_YQ eval '.global.kong | has("enterprise")' "$VKPR_GLOBAL_CONFIG") ]]; then
      KONG_ENTERPRISE=$($VKPR_YQ eval .global.kong.enterprise.enabled "$VKPR_GLOBAL_CONFIG")
      KONG_ENTERPRISE_LICENSE=$($VKPR_YQ eval .global.kong.enterprise.license "$VKPR_GLOBAL_CONFIG")
    fi

    rit vkpr kong install --enterprise "$KONG_ENTERPRISE" --license "$KONG_ENTERPRISE_LICENSE" --default
  fi
}

installLoki(){
  LOKI_EXISTS=$($VKPR_YQ eval .global.loki.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$LOKI_EXISTS" == true ]; then
    rit vkpr loki install --default
  fi
}

installPostgres(){
  POSTGRES_EXISTS=$($VKPR_YQ eval .global.postgresql.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$POSTGRES_EXISTS" == true ]; then
    rit vkpr postgres install --default
  fi
}

installPrometheusGrafana(){
  PROMETHEUS_STACK_EXISTS=$($VKPR_YQ eval .global.prometheus-stack.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$PROMETHEUS_STACK_EXISTS" == true ]; then
    rit vkpr prometheus-stack install --default
  fi
}

installVault(){
  VAULT_EXISTS=$($VKPR_YQ eval .global.vault.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$VAULT_EXISTS" == true ]; then
    rit vkpr vault install --default
  fi
}

installWhoami(){
  WHOAMI_EXISTS=$($VKPR_YQ eval .global.whoami.enabled "$VKPR_GLOBAL_CONFIG")
  if [ "$WHOAMI_EXISTS" == true ]; then
    rit vkpr whoami install --default
  fi
}