#!/bin/sh

runFormula() {
  VKPR_GLOBAL_CONFIG=~/.vkpr/global-values.yaml

  checkIfFileExists $PATHTOFILE
  applyConfig
  
}

checkIfFileExists(){
  FILE=$1
  if [[ -f "$FILE" ]]; then
    cp $FILE $VKPR_GLOBAL_CONFIG
  else
    echoColor "red" "Wrong file!"
    exit 1
  fi
}

applyConfig(){
#Order matters in this part!
#1 
    installIngress

#2 
    installWhoami

#3
    installCertManagerDO

#4
    installExternalDNS

#5
    installPostgres

#6
    installKeycloak

#7
    installPrometheusGrafana

#8
    installLoki

}

installIngress(){
  INGRESSEXISTS=$($VKPR_YQ eval .global.ingress.enabled $VKPR_GLOBAL_CONFIG)
  if [ "$INGRESSEXISTS" = true ]; then
    rit vkpr ingress install
  fi
  
}

installWhoami(){
  WHOAMIEXISTS=$($VKPR_YQ eval .global.whoami.enabled $VKPR_GLOBAL_CONFIG)
  if [ "$WHOAMIEXISTS" = true ]; then
    checkGlobalConfig $DOMAIN "localhost" "domain" "DOMAIN"
    rit vkpr whoami install --default
  fi
}

installExternalDNS(){
  PROVIDER_=$($VKPR_YQ eval .global.external-dns.provider $VKPR_GLOBAL_CONFIG)
  case $PROVIDER_ in
    digitalocean)
      installExternalDNSDO
      ;;
    aws)
      installExternalDNSAWS
      ;;
    PowerDNS)
      echoColor "red" "PowerDns in Apply fomula is a working in progress."
      ;;
    esac
}

installCertManagerDO(){
  CERTMANAGEREXISTS=$($VKPR_YQ eval .global.cert-manager.enabled $VKPR_GLOBAL_CONFIG)
  if [ "$CERTMANAGEREXISTS" = true ]; then
    DO_CREDENTIAL=$($VKPR_YQ eval .global.cert-manager.provider.digitalocean.digitalocean_token $VKPR_GLOBAL_CONFIG)
    if [ ! -z $DO_CREDENTIAL ]; then
      echoColor "yellow"  "Setting Digital Ocean Credential..."
      rit set credential --provider digitalocean --fields=token --values=$DO_CREDENTIAL
    fi
    DO_TOKEN_EXISTS=$(rit list credential | grep digitalocean)
    if [ ! -z "$DO_TOKEN_EXISTS" ]; then
      rit vkpr cert-manager install do --default
    else
      echoColor "red" "Skipping CERT_MANAGER installing due the digitalocean token missing..."
      echoColor "red" "Run rit set credentials or fill up the config file properly ..."
    fi
  fi
}

installExternalDNSDO(){
    EXTERNALDNSEXISTS=$($VKPR_YQ eval .global.external-dns.enabled $VKPR_GLOBAL_CONFIG)
    if [ "$EXTERNALDNSEXISTS" = true ]; then
    DO_CREDENTIAL=$($VKPR_YQ eval .global.external-dns.provider_token $VKPR_GLOBAL_CONFIG)
    if [ ! -z $DO_CREDENTIAL ]; then
      echoColor "yellow"  "Setting Digital Ocean Credential..."
      rit set credential --provider digitalocean --fields=token --values=$DO_CREDENTIAL
    fi
    DO_TOKEN_EXISTS=$(rit list credential | grep digitalocean)
    if [ ! -z "$DO_TOKEN_EXISTS" ]; then
      rit vkpr external-dns install --provider digitalocean --default
    else
      echoColor "red" "Skipping EXTERNAL-DNS installing due the digitalocean token missing..."
      echoColor "red" "Run rit set credentials or fill up the config file properly ..."
    fi
  fi
}

installExternalDNSAWS(){
  echoColor "red" "Cert-Manager with AWS is a work in progress."
}

installKeycloak(){
  KEYCLOAKEXISTS=$($VKPR_YQ eval .global.keycloak.enabled $VKPR_GLOBAL_CONFIG)
  echoColor "yellow" "teste: $KEYCLOAKEXISTS"
  if [ "$KEYCLOAKEXISTS" = true ]; then
    rit vkpr keycloak install --default
  fi

}

installPostgres(){
  POSTGRESEXISTS=$($VKPR_YQ eval .global.postgres.enabled $VKPR_GLOBAL_CONFIG)
    if [ "$POSTGRESEXISTS" = true ]; then
    PASSWORD=$($VKPR_YQ eval .global.postgres.admin_password $VKPR_GLOBAL_CONFIG)
    if [ ! -z $PASSWORD ]; then
      echoColor "yellow"  "Setting Postgres password..."
      rit set credential --provider postgres --fields=password --values=$PASSWORD
    fi
    PASSWORD_EXISTS=$(rit list credential | grep postgres)
    if [ ! -z "$PASSWORD_EXISTS" ]; then
      rit vkpr postgres install --default
    else
      echoColor "red" "Skipping POSTGRES installing due the password missing..."
      echoColor "red" "Run rit set credentials or fill up the config file properly ..."
    fi
  fi
}

installPrometheusGrafana(){
  PROMETHEUSGRAFANAEXISTS=$($VKPR_YQ eval .global.grafana.enabled $VKPR_GLOBAL_CONFIG)
  if [ "$PROMETHEUSGRAFANAEXISTS" = true ]; then
    rit vkpr prometheus-stack install --default
  fi
}

installLoki(){
  LOKIEXISTS=$($VKPR_YQ eval .global.loki.enabled $VKPR_GLOBAL_CONFIG)
  if [ "$LOKIEXISTS" = true ]; then
    rit vkpr loki install --default
  fi
}
