#!/usr/bin/env bats

# ~/.vkpr/bats/bin/bats vkpr-test/vault/vault.bats

export DETIK_CLIENT_NAMESPACE="vkpr"
load '../.bats/common.bats'

setup() {
  load "$VKPR_HOME/bats/bats-support/load"
  load "$VKPR_HOME/bats/bats-assert/load"
  load "$VKPR_HOME/bats/bats-detik/load"
  load "$VKPR_HOME/bats/bats-file/load"
}

setup_file() {
  touch $PWD/vkpr.yaml

  [ "$VKPR_TEST_SKIP_ALL" == "true" ] && echo "common_setup: skipping common_setup due to VKPR_TEST_SKIP_ALL=true" >&3 && return
  _common_setup "1" "false" "2"

  if [ "$VKPR_TEST_SKIP_PROVISIONING" == "true" ]; then
    echo "setup: skipping provisionig due to VKPR_TEST_SKIP_PROVISIONING=true" >&3
  else
    echo "setup: installing ingress..." >&3
    rit vkpr ingress install --default
    echo "setup: installing consul..." >&3
    rit vkpr consul install --default
    echo "setup: installing vault..." >&3
    rit vkpr vault install --default

  fi
}

teardown_file() {
  if [ "$VKPR_TEST_SKIP_ALL" == "true" ]; then
    echo "teardown: skipping uninstall due to VKPR_TEST_SKIP_ALL=true" >&3
    return
  fi

  if [ "$VKPR_TEST_SKIP_DEPLOY_ACTIONS" == "true" ]; then
    echo "common_setup: skipping common_setup due to VKPR_TEST_SKIP_DEPLOY_ACTIONS=true" >&3
  else
    echo "teardown: uninstalling vault..." >&3
    rit vkpr vault remove
    echo "teardown: uninstalling ingress..." >&3
    rit vkpr ingress remove
  fi

  _common_teardown
}

teardown() {
  $VKPR_YQ -i "del(.global) | del(.vault)" $PWD/vkpr.yaml
}

#=======================================#
#           INPUTS SECTION              #
#=======================================#

#--------#
# DOMAIN #
#--------#
        
# bats test_tags=input_domain, input_domain:flag
@test "check domain flag" {
  export VKPR_ENV_GLOBAL_DOMAIN="env.net"
  run $VKPR_YQ -i ".global.domain = \"config.net\"" $PWD/vkpr.yaml
  assert_success

  rit vkpr vault install --domain=input.net --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/server-ingress.yaml hashicorp/vault --version $VKPR_VAULT_VERSION > $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "vault.input.net"
}

# bats test_tags=input_domain, input_domain:file
@test "check domain file" {
  export VKPR_ENV_GLOBAL_DOMAIN="env.net"
  run $VKPR_YQ -i ".global.domain = \"config.net\"" $PWD/vkpr.yaml
  assert_success

  rit vkpr vault install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/server-ingress.yaml hashicorp/vault --version $VKPR_VAULT_VERSION > $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "vault.config.net"
}

# bats test_tags=input_domain, input_domain:env
@test "check domain env" {
  export VKPR_ENV_GLOBAL_DOMAIN="env.net"

  rit vkpr vault install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/server-ingress.yaml hashicorp/vault --version $VKPR_VAULT_VERSION > $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "vault.env.net"
}

# bats test_tags=input_domain, input_domain:default
@test "check domain default" {

  rit vkpr vault install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/server-ingress.yaml hashicorp/vault --version $VKPR_VAULT_VERSION > $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "vault.localhost"
}

#--------#
# SECURE #
#--------#

# bats test_tags=input_secure, input_secure:flag
@test "check secure flag" {

  export VKPR_ENV_GLOBAL_SECURE="true"
  run $VKPR_YQ -i ".global.secure = false" $PWD/vkpr.yaml
  assert_success

  rit vkpr vault install --secure --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/server-ingress.yaml hashicorp/vault --version $VKPR_VAULT_VERSION > $BATS_FILE_TMPDIR/temp.yaml
    
  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "true"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "vault.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "vault-cert"
}

# bats test_tags=input_secure, input_secure:file
@test "check secure file" {

  export VKPR_ENV_GLOBAL_SECURE="false"
  run $VKPR_YQ -i ".global.secure = true" $PWD/vkpr.yaml
  assert_success

  rit vkpr vault install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/server-ingress.yaml hashicorp/vault --version $VKPR_VAULT_VERSION > $BATS_FILE_TMPDIR/temp.yaml
    
  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "true"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "vault.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "vault-cert"
}

# bats test_tags=input_secure, input_secure:env
@test "check secure env" {
  export VKPR_ENV_GLOBAL_SECURE="true"

  rit vkpr vault install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/server-ingress.yaml hashicorp/vault --version $VKPR_VAULT_VERSION > $BATS_FILE_TMPDIR/temp.yaml
    
  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "true"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "vault.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "vault-cert"
}

# bats test_tags=input_secure, input_secure:default
@test "check secure default" {

  rit vkpr vault install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/server-ingress.yaml hashicorp/vault --version $VKPR_VAULT_VERSION > $BATS_FILE_TMPDIR/temp.yaml
    
  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "null"
}

#--------------#
# storage mode #
#--------------#

# bats test_tags=storage_mode, storage_mode:flag
@test "check storage-mode flag" {
  export VKPR_ENV_VAULT_STORAGE_MODE="consul"
  run $VKPR_YQ -i ".vault.storageMode = \"raft\"" $PWD/vkpr.yaml
  assert_success

  rit vkpr vault remove 
  rit vkpr vault install --mode="consul" 

  local i=0 \
  timeout=15 \

  while [[ $i -lt $timeout ]]; do
    if $VKPR_KUBECTL exec -it -n vkpr vault-0 -- cat vault/userconfig/vault-storage-config/config.hcl | grep -q storage; then
      break
    else
      sleep 1
      i=$((i+1))
    fi
  done

  storage=$($VKPR_KUBECTL exec -it -n vkpr vault-0 -- cat vault/userconfig/vault-storage-config/config.hcl | grep storage | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $storage
  assert_output "\"consul\""
}

# bats test_tags=storage_mode, storage_mode:file
@test "check storage-mode file" {
  export VKPR_ENV_VAULT_STORAGE_MODE="raft"
  run $VKPR_YQ -i ".vault.storageMode = \"consul\"" $PWD/vkpr.yaml
  assert_success

  rit vkpr vault remove  
  rit vkpr vault install --default  

  local i=0 \
  timeout=15 \

  while [[ $i -lt $timeout ]]; do
  
    if $VKPR_KUBECTL exec -it -n vkpr vault-0 -- cat vault/userconfig/vault-storage-config/config.hcl | grep -q storage; then
      break
    else
      sleep 1
      i=$((i+1))
    fi
  done

  storage=$($VKPR_KUBECTL exec -it -n vkpr vault-0 -- cat vault/userconfig/vault-storage-config/config.hcl | grep storage | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $storage
  assert_output "\"consul\""
}

# bats test_tags=storage_mode, storage_mode:env
@test "check storage-mode env" {
  export VKPR_ENV_VAULT_STORAGE_MODE="consul"

  rit vkpr vault remove  
  rit vkpr vault install --default 

  local i=0 \
  timeout=15 \

  while [[ $i -lt $timeout ]]; do
    if $VKPR_KUBECTL exec -it -n vkpr vault-0 -- cat vault/userconfig/vault-storage-config/config.hcl | grep -q storage; then
      break
    else
      sleep 1
      i=$((i+1))
    fi
  done

  storage=$($VKPR_KUBECTL exec -it -n vkpr vault-0 -- cat vault/userconfig/vault-storage-config/config.hcl | grep storage | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $storage
  assert_output "\"consul\""
}

# bats test_tags=storage_mode, storage_mode:default
@test "check storage-mode default" {

  rit vkpr vault remove  
  rit vkpr vault install --default  

  local i=0 \
  timeout=15 \

  while [[ $i -lt $timeout ]]; do
    if $VKPR_KUBECTL exec -it -n vkpr vault-0 -- cat vault/userconfig/vault-storage-config/config.hcl | grep -q storage; then
      break
    else
      sleep 1
      i=$((i+1))
    fi
  done

  storage=$($VKPR_KUBECTL exec -it -n vkpr vault-0 -- cat vault/userconfig/vault-storage-config/config.hcl | grep storage | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $storage
  assert_output "\"raft\""
}

#-----#
# SSL #
#-----#

# bats test_tags=input_ssl, input_ssl:flag
@test "check SSL flag" {
  createFileSSL

  export VKPR_ENV_VAULT_SSL="true" \
    VKPR_ENV_VAULT_SSL_CERTIFICATE="$BATS_FILE_TMPDIR/server.crt" \
    VKPR_ENV_VAULT_SSL_KEY="$BATS_FILE_TMPDIR/server.key"

  $VKPR_YQ -i ".vault.ssl.enabled = false |
   .vault.ssl.crt = \"$BATS_FILE_TMPDIR/server.crt\" |
   .vault.ssl.key = \"$BATS_FILE_TMPDIR/server.key\"" $PWD/vkpr.yaml

  rit vkpr vault install \
    --ssl --crt_file="$BATS_FILE_TMPDIR/server.crt" --key_file="$BATS_FILE_TMPDIR/server.key" --dry_run \
    | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/server-ingress.yaml hashicorp/vault --version $VKPR_VAULT_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  cat $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "vault.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "vault-certificate"

  crt_b64=$(cat $BATS_FILE_TMPDIR/server.crt | base64 -w0)
  key_b64=$(cat $BATS_FILE_TMPDIR/server.key | base64 -w0)

  run $VKPR_YQ ".data.\"tls.crt\"" vault-certificate.yaml
  assert_output "$crt_b64"
  run $VKPR_YQ ".data.\"tls.key\"" vault-certificate.yaml
  assert_output "$key_b64"
}

# bats test_tags=input_ssl, input_ssl:file
@test "check SSL file" {
  createFileSSL

  export VKPR_ENV_VAULT_SSL="false" \
    VKPR_ENV_VAULT_SSL_CERTIFICATE="$BATS_FILE_TMPDIR/server.crt" \
    VKPR_ENV_VAULT_SSL_KEY="$BATS_FILE_TMPDIR/server.key"

  $VKPR_YQ -i ".vault.ssl.enabled = true |
   .vault.ssl.crt = \"$BATS_FILE_TMPDIR/server.crt\" |
   .vault.ssl.key = \"$BATS_FILE_TMPDIR/server.key\"" $PWD/vkpr.yaml

  rit vkpr vault install --dry_run \
    | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/server-ingress.yaml hashicorp/vault --version $VKPR_VAULT_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  cat $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "vault.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "vault-certificate"

  crt_b64=$(cat $BATS_FILE_TMPDIR/server.crt | base64 -w0)
  key_b64=$(cat $BATS_FILE_TMPDIR/server.key | base64 -w0)

  run $VKPR_YQ ".data.\"tls.crt\"" vault-certificate.yaml
  assert_output "$crt_b64"
  run $VKPR_YQ ".data.\"tls.key\"" vault-certificate.yaml
  assert_output "$key_b64"

}

# bats test_tags=input_ssl, input_ssl:env
@test "check SSL env" {
  createFileSSL

  export VKPR_ENV_VAULT_SSL="true" \
    VKPR_ENV_VAULT_SSL_CERTIFICATE="$BATS_FILE_TMPDIR/server.crt" \
    VKPR_ENV_VAULT_SSL_KEY="$BATS_FILE_TMPDIR/server.key"

  rit vkpr vault install --dry_run \
    | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/server-ingress.yaml hashicorp/vault --version $VKPR_VAULT_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  cat $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "vault.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "vault-certificate"

  crt_b64=$(cat $BATS_FILE_TMPDIR/server.crt | base64 -w0)
  key_b64=$(cat $BATS_FILE_TMPDIR/server.key | base64 -w0)

  run $VKPR_YQ ".data.\"tls.crt\"" vault-certificate.yaml
  assert_output "$crt_b64"
  run $VKPR_YQ ".data.\"tls.key\"" vault-certificate.yaml
  assert_output "$key_b64"
}

# bats test_tags=input_ssl, input_ssl:default
@test "check SSL default" {

  rit vkpr vault install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/server-ingress.yaml hashicorp/vault --version $VKPR_VAULT_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  cat $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "null"
  
}


#-------------#
#  HELM ARGS  #
#-------------#

# bats test_tags=helm_args, helm_args:new
@test "check helmArgs adding new value" {
  $VKPR_YQ -i ".vault.helmArgs.server.ingress.PathType = \"Prefix\"" $PWD/vkpr.yaml

  rit vkpr vault install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/server-ingress.yaml hashicorp/vault --version $VKPR_VAULT_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  cat $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.rules[0].http.paths[0].pathType" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "Prefix"
}

# bats test_tags=helm_args, helm_args:change
@test "check helmArgs changing values" {
  $VKPR_YQ -i ".vault.helmArgs.server.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"false\"" $PWD/vkpr.yaml

  rit vkpr vault install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/server-ingress.yaml hashicorp/vault --version $VKPR_VAULT_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  cat $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "false"
}

#=======================================#
#          AUTOUNSEAL SECTION           #
#=======================================#
@test "unseal vault application and checking API" {

  local i=0 \
    timeout=50 \

  while [[ $i -lt $timeout ]]; do
    if $VKPR_KUBECTL exec -it -n vkpr vault-0 -- echo "OK"| grep -q "OK"; then
      $VKPR_KUBECTL exec -it -n vkpr vault-0 -- vault operator init -format=yaml > vault-auto-unseal-keys.txt 
      $VKPR_KUBECTL exec -it -n vkpr vault-0 -- vault operator unseal $(grep -A 5 unseal_keys_b64 vault-auto-unseal-keys.txt |head -2|tail -1|sed 's/- //g') && \
      $VKPR_KUBECTL exec -it -n vkpr vault-0 -- vault operator unseal $(grep -A 5 unseal_keys_b64 vault-auto-unseal-keys.txt |head -3|tail -1|sed 's/- //g') && \
      $VKPR_KUBECTL exec -it -n vkpr vault-0 -- vault operator unseal $(grep -A 5 unseal_keys_b64 vault-auto-unseal-keys.txt |head -4|tail -1|sed 's/- //g')
      break
    else
      sleep 1
      i=$((i+1))
    fi
  done
  
  sleep 2

  i=0
  while [[ $i -lt $timeout ]]; do
    if $VKPR_KUBECTL exec -it -n vkpr vault-1 -- echo "OK"| grep -q "OK"; then
      $VKPR_KUBECTL exec -it -n vkpr vault-1 -- vault operator unseal $(grep -A 5 unseal_keys_b64 vault-auto-unseal-keys.txt |head -2|tail -1|sed 's/- //g') && \
      $VKPR_KUBECTL exec -it -n vkpr vault-1 -- vault operator unseal $(grep -A 5 unseal_keys_b64 vault-auto-unseal-keys.txt |head -3|tail -1|sed 's/- //g') && \
      $VKPR_KUBECTL exec -it -n vkpr vault-1 -- vault operator unseal $(grep -A 5 unseal_keys_b64 vault-auto-unseal-keys.txt |head -4|tail -1|sed 's/- //g')

      break
    else
      sleep 1
      i=$((i+1))
    fi
  done

  sleep 2

  i=0
  while [[ $i -lt $timeout ]]; do
    if $VKPR_KUBECTL exec -it -n vkpr vault-2 -- echo "OK"| grep -q "OK"; then
      $VKPR_KUBECTL exec -it -n vkpr vault-2 -- vault operator unseal $(grep -A 5 unseal_keys_b64 vault-auto-unseal-keys.txt |head -2|tail -1|sed 's/- //g') && \
      $VKPR_KUBECTL exec -it -n vkpr vault-2 -- vault operator unseal $(grep -A 5 unseal_keys_b64 vault-auto-unseal-keys.txt |head -3|tail -1|sed 's/- //g') && \
      $VKPR_KUBECTL exec -it -n vkpr vault-2 -- vault operator unseal $(grep -A 5 unseal_keys_b64 vault-auto-unseal-keys.txt |head -4|tail -1|sed 's/- //g')
      break
    else
      sleep 1
      i=$((i+1))
    fi
  done
  export VAULT_ROOT_TOKEN=$(cat vault-auto-unseal-keys.txt | grep root_token | tr -s '[:space:]' ' ' | cut -d " " -f2)
  rm vault-auto-unseal-keys.txt

  # testing API requests

  $VKPR_KUBECTL exec -it -n vkpr vault-0 -- vault login $VAULT_ROOT_TOKEN && \
  $VKPR_KUBECTL exec -it -n vkpr vault-0 -- vault secrets enable -version=1 kv && \
  $VKPR_KUBECTL exec -it -n vkpr vault-0 -- vault kv put kv/path key=secretpassword 

  curl -s -H "X-Vault-Token: $VAULT_ROOT_TOKEN" -X GET http://vault.localhost:8000/v1/kv/path

  SECRET=$(curl -s -H "X-Vault-Token: $VAULT_ROOT_TOKEN" -X GET http://vault.localhost:8000/v1/kv/path | jq .data.key)
  run echo $SECRET
  assert_output "\"secretpassword\""
}

#=======================================#
#         INSTALLATION SECTION          #
#=======================================#

@test "check application health" {

    local i=0 \
      timeout=10 \

  while [[ $i -lt $timeout ]]; do
    if curl -is http://vault.localhost:8000/ | head -n1 | awk -F' ' '{print $2}' | grep -q "200"; then
      break
    else
      sleep 1
      i=$((i+1))
    fi
  done

  local VAULT_STATUS_HELM=$($VKPR_HELM ls -n vkpr | grep vault | tr -s '[:space:]' ' ' | cut -d " " -f8 )

  run echo $VAULT_STATUS_HELM
  assert_output "deployed"

  vault_status=$($VKPR_KUBECTL get po -n vkpr | grep -i "Running" | grep -i vault-agent-injector | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $vault_status
  assert_output "1/1"

  vault_status=$($VKPR_KUBECTL get po -n vkpr | grep -i "Running" | grep -i vault-0 | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $vault_status 
  assert_output "1/1"

  vault_status=$($VKPR_KUBECTL get po -n vkpr | grep -i "Running" | grep -i vault-1 | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $vault_status 
  assert_output "1/1"

  vault_status=$($VKPR_KUBECTL get po -n vkpr | grep -i "Running" | grep -i vault-2 | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $vault_status 
  assert_output "1/1"

}

@test "hit application health" {

  RESPONSE=$(curl -is http://vault.localhost:8000/ui/vault/auth?with=token | head -n1 | awk -F' ' '{print $2}')
  run echo $RESPONSE
  assert_output "200"
}

#=======================================#
#            OBJECT SECTION             #
#=======================================#

  #----------#
  #  Secret  #
  #----------#

  # vault-storage-config
@test "check vault-storage-config secret" {
  vault_secret_name=$($VKPR_KUBECTL get secret -n vkpr | grep vault-storage-config | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $vault_secret_name 
  assert_output "vault-storage-config"

  vault_secret_data=$($VKPR_KUBECTL get secret -n vkpr | grep vault-storage-config | tr -s '[:space:]' ' ' | cut -d " " -f3)
  run echo $vault_secret_data 
  assert_output "1"
}

  # sh.helm.release.v1.vault.v1
@test "check sh.helm.release.v1.vault.v1 secret" {
  vault_secret_name=$($VKPR_KUBECTL get secret -n vkpr | grep sh.helm.release.v1.vault.v1 | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $vault_secret_name 
  assert_output "sh.helm.release.v1.vault.v1"

  vault_secret_data=$($VKPR_KUBECTL get secret -n vkpr | grep sh.helm.release.v1.vault.v1 | tr -s '[:space:]' ' ' | cut -d " " -f3)
  run echo $vault_secret_data 
  assert_output "1"
}

  #-----------#
  #  Service  #
  #-----------#

  # vault-internal
@test "check vault-internal service" {
  vault_service_name=$($VKPR_KUBECTL get svc -n vkpr | grep vault-internal | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $vault_service_name 
  assert_output "vault-internal"

  vault_service_type=$($VKPR_KUBECTL get svc -n vkpr | grep vault-internal | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $vault_service_type 
  assert_output "ClusterIP"
}

  # vault-standby
@test "check vault-standby service" {
  vault_service_name=$($VKPR_KUBECTL get svc -n vkpr | grep vault-standby | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $vault_service_name 
  assert_output "vault-standby"

  vault_service_type=$($VKPR_KUBECTL get svc -n vkpr | grep vault-standby | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $vault_service_type 
  assert_output "ClusterIP"
}

  # vault-active
@test "check vault-active service" {
  vault_service_name=$($VKPR_KUBECTL get svc -n vkpr | grep vault-active | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $vault_service_name 
  assert_output "vault-active"

  vault_service_type=$($VKPR_KUBECTL get svc -n vkpr | grep vault-active | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $vault_service_type 
  assert_output "ClusterIP"
}

  # vault-agent-injector-svc
@test "check vault-agent-injector-svc service" {
  vault_service_name=$($VKPR_KUBECTL get svc -n vkpr | grep vault-agent-injector-svc | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $vault_service_name 
  assert_output "vault-agent-injector-svc"

  vault_service_type=$($VKPR_KUBECTL get svc -n vkpr | grep vault-agent-injector-svc | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $vault_service_type 
  assert_output "ClusterIP"
}

#=======================================#
#         INTEGRATION SECTION           #
#=======================================#

createFileSSL() {
  openssl genrsa -out $BATS_FILE_TMPDIR/server.key 2048
  openssl rsa -in $BATS_FILE_TMPDIR/server.key -out $BATS_FILE_TMPDIR/server.key
  openssl req -sha256 -new -key $BATS_FILE_TMPDIR/server.key -out $BATS_FILE_TMPDIR/server.csr -subj '/CN=localhost'
  openssl x509 -req -sha256 -days 365 -in $BATS_FILE_TMPDIR/server.csr -signkey $BATS_FILE_TMPDIR/server.key -out $BATS_FILE_TMPDIR/server.crt
}