#!/usr/bin/env bash

dryRunK8s(){
  if [ $DRY_RUN = true ]; then
    trace "Creating file $CURRENT_PWD/$1.yaml by dry_run=true"
    echo "--dry-run=client -o=yaml > $CURRENT_PWD/$1.yaml"
    return 0
  fi
  echo "> /dev/null"
}

createKongSecretsEnterprise() {
  local DRY_FLAG="$(dryRunK8s "kong-enterprise-license")"
  info "Creating the Kong Secrets..."

  [[ "$VKPR_ENVIRONMENT" != "okteto" ]] && KONG_NAMESPACE="-n=$VKPR_ENV_KONG_NAMESPACE"

  ## Create license (enable manager)
  mkdir -p /tmp/vkpr

  local LICENSE_CONTENT=$(cat $VKPR_ENV_KONG_ENTERPRISE_LICENSE 2> /dev/null )

  trace "Creating kong-enterprise secret with name kong-enterprise-license"
  if [[ -z $LICENSE_CONTENT ]]; then
      eval $VKPR_KUBECTL create secret generic kong-enterprise-license $KONG_NAMESPACE --from-literal=license="" $DRY_FLAG
    else
      eval $VKPR_KUBECTL create secret generic kong-enterprise-license $KONG_NAMESPACE --from-file=$VKPR_ENV_KONG_ENTERPRISE_LICENSE $DRY_FLAG
    fi

  RESULT=$?
  debug "Create Kong enterprise secret status = $RESULT"
  [ $DRY_RUN = false ] && trace "$($VKPR_KUBECTL label secret/kong-enterprise-license app\.kubernetes\.io/managed-by=vkpr "$KONG_NAMESPACE")"
  debug "kong-enterprise-license"
}

createKongTlsSecrets() {
  local DRY_FLAG="$(dryRunK8s "kong-cluster-cert")"

  ## Create Kong tls secret to communicate between planes
  eval $VKPR_KUBECTL create secret tls kong-cluster-cert \
    --cert=$VKPR_HOME/certs/cluster.crt --key=$VKPR_HOME/certs/cluster.key $KONG_NAMESPACE $DRY_FLAG
    
  RESULT=$?
  debug "Create Kong cluster cert secret status = $RESULT"
  [ $DRY_RUN = false ] && trace "$($VKPR_KUBECTL label secret/kong-cluster-cert app\.kubernetes\.io/managed-by=vkpr "$KONG_NAMESPACE")"
  debug "kong-cluster-cert"
}

createKongCookieconfig(){
  local DRY_FLAG="$(dryRunK8s "kong-session-config")"

  # shellcheck source=src/util.sh
  source "$(dirname "$0")"/unix/formula/files.sh

  ## Create Kong cookie config
  eval $VKPR_KUBECTL create secret generic kong-session-config \
    --from-file=/tmp/config/admin_gui_session_conf \
    --from-file=/tmp/config/portal_session_conf $KONG_NAMESPACE $DRY_FLAG

  RESULT=$?
  debug "Create Kong session conf secret status = $RESULT"
  [ $DRY_RUN = false ] && trace "$($VKPR_KUBECTL label secret/kong-session-config app\.kubernetes\.io/managed-by=vkpr "$KONG_NAMESPACE")"
  debug "kong-session-config"

}

createKongRbacSecret(){
  local DRY_FLAG="$(dryRunK8s "kong-enterprise-superuser-password")"

  ## Create Kong RBAC password
  eval $VKPR_KUBECTL create secret generic kong-enterprise-superuser-password --from-literal="password=$VKPR_ENV_KONG_RBAC_ADMIN_PASSWORD" $KONG_NAMESPACE $DRY_FLAG

  RESULT=$?
  debug "Create kong-enterprise-superuser-password status = $RESULT"
  [ $DRY_RUN = false ] && trace "$($VKPR_KUBECTL label secret/kong-enterprise-superuser-password app\.kubernetes\.io/managed-by=vkpr "$KONG_NAMESPACE")"
  debug "kong-enterprise-superuser-password"
}

createKongPostgresqlSecret (){
  ## Check if exist postgresql password secret in Kong namespace, if not, create one
  if ! $VKPR_KUBECTL get secret $KONG_NAMESPACE | grep -q postgres-postgresql; then
    local DRY_FLAG="$(dryRunK8s "postgres-postgresql")"
    PG_PASSWORD=$($VKPR_KUBECTL get secret postgres-postgresql -o=jsonpath="{.data.postgres-password}" -n "$VKPR_ENV_POSTGRESQL_NAMESPACE" | base64 -d -)

    eval $VKPR_KUBECTL create secret generic postgres-postgresql --from-literal="postgres-password=$PG_PASSWORD" $KONG_NAMESPACE $DRY_FLAG

    RESULT=$?
    debug "Create postgres-postgresql status = $RESULT"
    [ $DRY_RUN = false ] && trace "$($VKPR_KUBECTL label secret/postgres-postgresql app\.kubernetes\.io/managed-by=vkpr "$KONG_NAMESPACE")"
    debug "postgres-postgresql"
  fi
}

createKongOpenidSecret(){
  if [[ $VKPR_ENV_KONG_KEYCLOAK_OPENID == "true" ]]; then
    local DRY_FLAG="$(dryRunK8s "kong-idp-config")"

    eval $VKPR_KUBECTL create secret generic kong-idp-config \
      --from-file="$(dirname "$0")"/utils/admin_gui_auth_conf $KONG_NAMESPACE $DRY_FLAG
     
    RESULT=$?
    debug "Create $PG_SECRET status = $RESULT"
    [ $DRY_RUN = false ] && trace "$($VKPR_KUBECTL label secret/kong-idp-config app\.kubernetes\.io/managed-by=vkpr "$KONG_NAMESPACE")"
    debug "kong-idp-config"
  fi
}

createKongSecretsBasicAuth() {
  local DRY_FLAG="$(dryRunK8s "kong-admin-basicauth")"

  eval $VKPR_KUBECTL create secret generic kong-admin-basicauth -n $VKPR_ENV_KONG_NAMESPACE \
    --from-literal="kongCredType=basic-auth" \
    --from-literal=username=kong_admin \
    --from-literal=password=$VKPR_ENV_KONG_RBAC_ADMIN_PASSWORD $DRY_FLAG

  RESULT=$?
  debug "Create $PG_SECRET status = $RESULT"
  [ $DRY_RUN = false ] && trace "$($VKPR_KUBECTL label secret/kong-admin-basicauth app\.kubernetes\.io/managed-by=vkpr "$KONG_NAMESPACE")"
  debug "kong-admin-basicauth"
}

createKongKeyringSecret (){
  ## Create Kong keyring secret for encrypted communication between databases
  if [[ "$VKPR_ENV_KONG_ENTERPRISE_LICENSE" != "null" ]]; then
    local DRY_FLAG="$(dryRunK8s "kong-keyring-cert")"

    openssl genrsa -out  $VKPR_HOME/certs/key.pem 2048 
    openssl rsa -in  $VKPR_HOME/certs/key.pem -pubout -out  $VKPR_HOME/certs/cert.pem &> /dev/null

    eval $VKPR_KUBECTL create secret generic kong-keyring-cert \
      --from-file=$VKPR_HOME/certs/cert.pem --from-file=$VKPR_HOME/certs/key.pem $KONG_NAMESPACE $DRY_FLAG
    
    RESULT=$?
    debug "Create $PG_SECRET status = $RESULT"
    [ $DRY_RUN = false ] && trace "$($VKPR_KUBECTL label secret/kong-keyring-cert app\.kubernetes\.io/managed-by=vkpr "$KONG_NAMESPACE")"
    debug "kong-keyring-cert"
  fi
}

createSecretsKongCp(){
  createKongSecretsEnterprise
  createKongTlsSecrets
  createKongCookieconfig
  createKongRbacSecret
  createKongPostgresqlSecret
  createKongOpenidSecret
}

createSecretsKongDp(){
  createKongSecretsEnterprise
  createKongTlsSecrets
}

createSecretsKongDbless(){
  createKongSecretsEnterprise
  createKongSecretsBasicAuth
}

createSecretsKongStandard(){
  createKongSecretsEnterprise
  createKongCookieconfig
  createKongRbacSecret
  createKongPostgresqlSecret
  createKongOpenidSecret
  createKongKeyringSecret
}