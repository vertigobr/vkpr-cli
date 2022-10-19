#!/usr/bin/env bats

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
  _common_setup "1" "false" "1"

  if [ "$VKPR_TEST_SKIP_DEPLOY_ACTIONS" == "true" ]; then
    echo "common_setup: skipping common_setup due to VKPR_TEST_SKIP_DEPLOY_ACTIONS=true" >&3
    return
  else
    echo "Install ingress" >&3
    rit vkpr ingress install --default
  fi
}

teardown_file() {
  if [ "$VKPR_TEST_SKIP_ALL" == "true" ]; then
    echo "common_setup: skipping common_setup due to VKPR_TEST_SKIP_ALL=true" >&3
    return
  fi

  if [ "$VKPR_TEST_SKIP_DEPLOY_ACTIONS" == "true" ]; then
    echo "common_setup: skipping common_setup due to VKPR_TEST_SKIP_DEPLOY_ACTIONS=true" >&3
  else
    echo "Uninstall whoami" >&3
    rit vkpr whoami remove
  fi

  _common_teardown
}

teardown() {
  $VKPR_YQ -i "del(.global) | del(.whoami)" $PWD/vkpr.yaml
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

  rit vkpr whoami install --domain=input.net --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/ingress.yaml cowboysysop/whoami --version $VKPR_WHOAMI_VERSION > $BATS_FILE_TMPDIR/manifest.yaml
  
  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "whoami.input.net"
}

# bats test_tags=input_domain, input_domain:file
@test "check domain file" {
  export VKPR_ENV_GLOBAL_DOMAIN="env.net"
  run $VKPR_YQ -i ".global.domain = \"config.net\"" $PWD/vkpr.yaml
  assert_success

  rit vkpr whoami install --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/ingress.yaml cowboysysop/whoami --version $VKPR_WHOAMI_VERSION > $BATS_FILE_TMPDIR/manifest.yaml
  
  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "whoami.config.net"
}

# bats test_tags=input_domain, input_domain:env
@test "check domain env" {
  export VKPR_ENV_GLOBAL_DOMAIN="env.net"

  rit vkpr whoami install --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/ingress.yaml cowboysysop/whoami --version $VKPR_WHOAMI_VERSION > $BATS_FILE_TMPDIR/manifest.yaml
  
  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "whoami.env.net"
}

# bats test_tags=input_domain, input_domain:default
@test "check domain default" {
  rit vkpr whoami install --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/ingress.yaml cowboysysop/whoami --version $VKPR_WHOAMI_VERSION > $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "whoami.localhost"
}

#--------#
# SECURE #
#--------#

# bats test_tags=input_secure, input_secure:flag
@test "check secure flag" {
  export VKPR_ENV_GLOBAL_SECURE="true"
  $VKPR_YQ -i ".global.secure = false" $PWD/vkpr.yaml

  rit vkpr whoami install --secure --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/ingress.yaml cowboysysop/whoami --version $VKPR_WHOAMI_VERSION > $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "true"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "whoami.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "whoami-cert"
}

# bats test_tags=input_secure, input_secure:file
@test "check secure file" {
  export VKPR_ENV_GLOBAL_SECURE="true"
  $VKPR_YQ -i ".global.secure = false" $PWD/vkpr.yaml

  rit vkpr whoami install --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/ingress.yaml cowboysysop/whoami --version $VKPR_WHOAMI_VERSION > $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "null"
}

# bats test_tags=input_secure, input_secure:env
@test "check secure env" {
  export VKPR_ENV_GLOBAL_SECURE="true"

  rit vkpr whoami install --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/ingress.yaml cowboysysop/whoami --version $VKPR_WHOAMI_VERSION > $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "true"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "whoami.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "whoami-cert"
}

# bats test_tags=input_secure, input_secure:default
@test "check secure default" {
  rit vkpr whoami install --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/ingress.yaml cowboysysop/whoami --version $VKPR_WHOAMI_VERSION > $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "null"
}

#--------------------#
# INGRESS CLASS NAME #
#--------------------#

# bats test_tags=input_classname, input_classname:file_specific
@test "check ingressClassName file specific" {
  export VKPR_ENV_WHOAMI_INGRESS_CLASS_NAME="traefik"
  $VKPR_YQ -i ".global.ingressClassName = \"kong\" | .whoami.ingressClassName = \"test\"" $PWD/vkpr.yaml

  rit vkpr whoami install --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/ingress.yaml cowboysysop/whoami --version $VKPR_WHOAMI_VERSION > $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".spec.ingressClassName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "test"
}

# bats test_tags=input_classname, input_classname:file_global
@test "check ingressClassName file global" {
  $VKPR_YQ -i ".global.ingressClassName = \"kong\"" $PWD/vkpr.yaml

  rit vkpr whoami install --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/ingress.yaml cowboysysop/whoami --version $VKPR_WHOAMI_VERSION > $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".spec.ingressClassName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "kong"
}

# bats test_tags=input_classname, input_classname:env
@test "check ingressClassName env" {
  export VKPR_ENV_WHOAMI_INGRESS_CLASS_NAME="traefik"
  $VKPR_YQ -i ".global.ingressClassName = \"kong\"" $PWD/vkpr.yaml

  rit vkpr whoami install --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/ingress.yaml cowboysysop/whoami --version $VKPR_WHOAMI_VERSION > $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".spec.ingressClassName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "traefik"
}

# bats test_tags=input_classname, input_classname:default
@test "check ingressClassName default" {
  rit vkpr whoami install --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/ingress.yaml cowboysysop/whoami --version $VKPR_WHOAMI_VERSION > $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".spec.ingressClassName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "nginx"
}

#-----#
# SSL #
#-----#

# bats test_tags=input_ssl, input_ssl:flag
@test "check SSL flag" {
  createFileSSL

  export VKPR_ENV_WHOAMI_SSL="true" \
    VKPR_ENV_WHOAMI_SSL_CERTIFICATE="$BATS_FILE_TMPDIR/server.crt" \
    VKPR_ENV_WHOAMI_SSL_KEY="$BATS_FILE_TMPDIR/server.key"

  $VKPR_YQ -i ".whoami.ssl.enabled = false |
   .whoami.ssl.crt = \"$BATS_FILE_TMPDIR/server.crt\" |
   .whoami.ssl.key = \"$BATS_FILE_TMPDIR/server.key\"" $PWD/vkpr.yaml

  rit vkpr whoami install \
    --ssl --crt_file="$BATS_FILE_TMPDIR/server.crt" --key_file="$BATS_FILE_TMPDIR/server.key" --dry_run \
    | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/ingress.yaml cowboysysop/whoami --version $VKPR_WHOAMI_VERSION > $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "whoami.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "whoami-certificate"

  crt_b64=$(cat $BATS_FILE_TMPDIR/server.crt | base64 -w0)
  key_b64=$(cat $BATS_FILE_TMPDIR/server.key | base64 -w0)

  assert_file_exist $PWD/tls-secret.yaml
  mv $PWD/tls-secret.yaml $BATS_FILE_TMPDIR/tls-secret.yaml

  run $VKPR_YQ ".data.\"tls.crt\"" $BATS_FILE_TMPDIR/tls-secret.yaml
  assert_output "$crt_b64"
  run $VKPR_YQ ".data.\"tls.key\"" $BATS_FILE_TMPDIR/tls-secret.yaml
  assert_output "$key_b64"
}

# bats test_tags=input_ssl, input_ssl:file
@test "check SSL file" {
  createFileSSL

  export VKPR_ENV_WHOAMI_SSL="false" \
    VKPR_ENV_WHOAMI_SSL_CERTIFICATE="$BATS_FILE_TMPDIR/server.crt" \
    VKPR_ENV_WHOAMI_SSL_KEY="$BATS_FILE_TMPDIR/server.key"

  $VKPR_YQ -i ".whoami.ssl.enabled = true |
   .whoami.ssl.crt = \"$BATS_FILE_TMPDIR/server.crt\" |
   .whoami.ssl.key = \"$BATS_FILE_TMPDIR/server.key\"" $PWD/vkpr.yaml


  rit vkpr whoami install --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/ingress.yaml cowboysysop/whoami --version $VKPR_WHOAMI_VERSION > $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "whoami.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "whoami-certificate"

  crt_b64=$(cat $BATS_FILE_TMPDIR/server.crt | base64 -w0)
  key_b64=$(cat $BATS_FILE_TMPDIR/server.key | base64 -w0)

  assert_file_exist $PWD/tls-secret.yaml
  mv $PWD/tls-secret.yaml $BATS_FILE_TMPDIR/tls-secret.yaml

  run $VKPR_YQ ".data.\"tls.crt\"" $BATS_FILE_TMPDIR/tls-secret.yaml
  assert_output "$crt_b64"
  run $VKPR_YQ ".data.\"tls.key\"" $BATS_FILE_TMPDIR/tls-secret.yaml
  assert_output "$key_b64"
}

# bats test_tags=input_ssl, input_ssl:env
@test "check SSL env" {
  createFileSSL

  export VKPR_ENV_WHOAMI_SSL="true" \
    VKPR_ENV_WHOAMI_SSL_CERTIFICATE="$BATS_FILE_TMPDIR/server.crt" \
    VKPR_ENV_WHOAMI_SSL_KEY="$BATS_FILE_TMPDIR/server.key"

  rit vkpr whoami install --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/ingress.yaml cowboysysop/whoami --version $VKPR_WHOAMI_VERSION > $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "whoami.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "whoami-certificate"

  crt_b64=$(cat $BATS_FILE_TMPDIR/server.crt | base64 -w0)
  key_b64=$(cat $BATS_FILE_TMPDIR/server.key | base64 -w0)

  assert_file_exist $PWD/tls-secret.yaml
  mv $PWD/tls-secret.yaml $BATS_FILE_TMPDIR/tls-secret.yaml

  run $VKPR_YQ ".data.\"tls.crt\"" $BATS_FILE_TMPDIR/tls-secret.yaml
  assert_output "$crt_b64"
  run $VKPR_YQ ".data.\"tls.key\"" $BATS_FILE_TMPDIR/tls-secret.yaml
  assert_output "$key_b64"
}

# bats test_tags=input_ssl, input_ssl:default
@test "check SSL default" {
  createFileSSL

  rit vkpr whoami install --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/ingress.yaml cowboysysop/whoami --version $VKPR_WHOAMI_VERSION > $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "null"

  assert_file_not_exist $PWD/tls-secret.yaml
}

#-------------#
#  HELM ARGS  #
#-------------#

# bats test_tags=helm_args, helm_args:new
@test "check helmArgs adding new value" {
  $VKPR_YQ -i ".whoami.helmArgs.ingress.PathType = \"Prefix\"" $PWD/vkpr.yaml

  rit vkpr whoami install --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/ingress.yaml cowboysysop/whoami --version $VKPR_WHOAMI_VERSION > $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".spec.rules[0].http.paths[0].pathType" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "Prefix"
}

# bats test_tags=helm_args, helm_args:change
@test "check helmArgs changing values" {
  $VKPR_YQ -i ".whoami.helmArgs.ingress.annotations.[\"kubernetes.io/tls-acme\"] = false" $PWD/vkpr.yaml

  rit vkpr whoami install --secure --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/ingress.yaml cowboysysop/whoami --version $VKPR_WHOAMI_VERSION > $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "false"
}

#=======================================#
#         INSTALLATION SECTION          #
#=======================================#

# bats test_tags=install, install:health
@test "check application health" {
  rit vkpr whoami install --default

  whoami_status=$($VKPR_KUBECTL get po -n vkpr | grep whoami | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $whoami_status 
  assert_output "1/1"
  
  whoami_status=$($VKPR_KUBECTL get po -n vkpr | grep whoami | tr -s '[:space:]' ' ' | cut -d " " -f3)
  run echo $whoami_status
  assert_output "Running"
}

# bats test_tags=install, install:target
@test "hit application health" {
  rit vkpr whoami install --default

  run curl -LIsw "%{http_code}" -o /dev/null http://whoami.localhost:8000
  assert_output "200"

  rit vkpr ingress remove
}

#=======================================#
#            OBJECT SECTION             #
#=======================================#

# bats test_tags=app_objects, app_objects:secret_tls
@test "create TLS secret" {
  createFileSSL

  rit vkpr whoami install \
    --ssl --crt_file="$BATS_FILE_TMPDIR/server.crt" --key_file="$BATS_FILE_TMPDIR/server.key"
  
  $VKPR_KUBECTL get secret whoami-certificate -n vkpr -o yaml > $BATS_FILE_TMPDIR/tls-secret.yaml

  crt_b64=$(cat $BATS_FILE_TMPDIR/server.crt | base64 -w0)
  key_b64=$(cat $BATS_FILE_TMPDIR/server.key | base64 -w0)

  assert_file_exist $BATS_FILE_TMPDIR/tls-secret.yaml

  run $VKPR_YQ ".data.\"tls.crt\"" $BATS_FILE_TMPDIR/tls-secret.yaml
  assert_output "$crt_b64"
  run $VKPR_YQ ".data.\"tls.key\"" $BATS_FILE_TMPDIR/tls-secret.yaml
  assert_output "$key_b64"
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