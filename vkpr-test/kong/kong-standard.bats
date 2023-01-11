#!/usr/bin/env bats

# ~/.vkpr/bats/bin/bats vkpr-test/kong/kong-standard.bats

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
    echo "setup: installing kong..." >&3
    rit vkpr kong install --mode="standard" --default
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
    echo "Uninstall kong" >&3
    rit vkpr kong remove
  fi

  _common_teardown
}

teardown() {
  $VKPR_YQ -i "del(.global) | del(.kong)" $PWD/vkpr.yaml
}

#--------------#
# CALLS TO API #
#--------------#

@test "curl to Kong domain with HTTP" {
    local i=0 \
        timeout=15 \
        KONG_ADDR="http://api.manager.localhost:8000"
        HEADERS="Kong-Admin-Token: vkpr123"
        
  while [[ $i -lt $timeout ]]; do
    if $VKPR_DECK ping --kong-addr="$KONG_ADDR" --headers=$HEADERS | grep -q "Successfully"; then
      break
    else
      sleep 1
      i=$((i+1))
    fi
  done

  RESPONSE=$(curl -is -H 'Kong-Admin-Token:"vkpr123"' manager.localhost:8000 | head -n1 | awk -F' ' '{print $2}')

  run echo $RESPONSE
  assert_output "200"
  assert_success
}

@test "curl to Kong manager with HTTP" {
  RESPONSE=$(curl -is -H 'Kong-Admin-Token:"vkpr123"' api.manager.localhost:8000 | head -n1 | awk -F' ' '{print $2}')

  run echo $RESPONSE
  assert_output "200"
  assert_success
}

@test "curl to Kong with no headers" {
  RESPONSE=$(curl -is localhost:8000 | head -n1 | awk -F' ' '{print $2}')

  run echo $RESPONSE
  assert_output "404"
  assert_success
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

  rit vkpr kong install --mode="standard" --domain=input.net --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/service-kong-admin.yaml kong/kong --version $VKPR_KONG_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  tail -n +2 $BATS_FILE_TMPDIR/temp.yaml > $BATS_FILE_TMPDIR/manifest.yaml
  csplit $BATS_FILE_TMPDIR/manifest.yaml '/\-\-\-/' -f $BATS_FILE_TMPDIR/manifest.yaml -n "0" | mv -f $BATS_FILE_TMPDIR/manifest.yaml1 $BATS_FILE_TMPDIR/manifest.yaml | rm -f $BATS_FILE_TMPDIR/manifest.yaml0  
  
  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/manifest.yaml 
  assert_output "api.manager.input.net"
}

# bats test_tags=input_domain, input_domain:file
@test "check domain file" {
  export VKPR_ENV_GLOBAL_DOMAIN="env.net"
  run $VKPR_YQ -i ".global.domain = \"config.net\"" $PWD/vkpr.yaml
  assert_success

  rit vkpr kong install --mode="standard" --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/service-kong-admin.yaml kong/kong --version $VKPR_KONG_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  tail -n +2 $BATS_FILE_TMPDIR/temp.yaml > $BATS_FILE_TMPDIR/manifest.yaml
  csplit $BATS_FILE_TMPDIR/manifest.yaml '/\-\-\-/' -f $BATS_FILE_TMPDIR/manifest.yaml -n "0" | mv -f $BATS_FILE_TMPDIR/manifest.yaml1 $BATS_FILE_TMPDIR/manifest.yaml | rm -f $BATS_FILE_TMPDIR/manifest.yaml0  
  
  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/manifest.yaml 
  assert_output "api.manager.config.net"
}

# bats test_tags=input_domain, input_domain:env
@test "check domain env" {
  export VKPR_ENV_GLOBAL_DOMAIN="env.net"

  rit vkpr kong install --mode="standard" --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/service-kong-admin.yaml kong/kong --version $VKPR_KONG_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  tail -n +2 $BATS_FILE_TMPDIR/temp.yaml > $BATS_FILE_TMPDIR/manifest.yaml
  csplit $BATS_FILE_TMPDIR/manifest.yaml '/\-\-\-/' -f $BATS_FILE_TMPDIR/manifest.yaml -n "0" | mv -f $BATS_FILE_TMPDIR/manifest.yaml1 $BATS_FILE_TMPDIR/manifest.yaml | rm -f $BATS_FILE_TMPDIR/manifest.yaml0  
  
  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/manifest.yaml 
  assert_output "api.manager.env.net"
}

# bats test_tags=input_domain, input_domain:default
@test "check domain default" {
  
  rit vkpr kong install --mode="standard" --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/service-kong-admin.yaml kong/kong --version $VKPR_KONG_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  tail -n +2 $BATS_FILE_TMPDIR/temp.yaml > $BATS_FILE_TMPDIR/manifest.yaml
  csplit $BATS_FILE_TMPDIR/manifest.yaml '/\-\-\-/' -f $BATS_FILE_TMPDIR/manifest.yaml -n "0" | mv -f $BATS_FILE_TMPDIR/manifest.yaml1 $BATS_FILE_TMPDIR/manifest.yaml | rm -f $BATS_FILE_TMPDIR/manifest.yaml0  

  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/manifest.yaml 
  assert_output "api.manager.localhost"
}

#--------#
# SECURE #
#--------#

# bats test_tags=input_secure, input_secure:flag
@test "check secure flag" {
  export VKPR_ENV_GLOBAL_SECURE="true"
  run $VKPR_YQ -i ".global.secure = false" $PWD/vkpr.yaml
  assert_success

  rit vkpr kong install --mode="standard" --secure --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/service-kong-admin.yaml kong/kong --version $VKPR_KONG_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  tail -n +2 $BATS_FILE_TMPDIR/temp.yaml > $BATS_FILE_TMPDIR/manifest.yaml
  csplit $BATS_FILE_TMPDIR/manifest.yaml '/\-\-\-/' -f $BATS_FILE_TMPDIR/manifest.yaml -n "0" | mv -f $BATS_FILE_TMPDIR/manifest.yaml1 $BATS_FILE_TMPDIR/manifest.yaml | rm -f $BATS_FILE_TMPDIR/manifest.yaml0  
  
  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "true"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "api.manager.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "admin-kong-cert"
}

# bats test_tags=input_secure, input_secure:file
@test "check secure file" {
  export VKPR_ENV_GLOBAL_SECURE="true"
  run $VKPR_YQ -i ".global.secure = false" $PWD/vkpr.yaml
  assert_success

  rit vkpr kong install --mode="standard" --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/service-kong-admin.yaml kong/kong --version $VKPR_KONG_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  tail -n +2 $BATS_FILE_TMPDIR/temp.yaml > $BATS_FILE_TMPDIR/manifest.yaml
  csplit $BATS_FILE_TMPDIR/manifest.yaml '/\-\-\-/' -f $BATS_FILE_TMPDIR/manifest.yaml -n "0" | mv -f $BATS_FILE_TMPDIR/manifest.yaml1 $BATS_FILE_TMPDIR/manifest.yaml | rm -f $BATS_FILE_TMPDIR/manifest.yaml0  
  
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

  rit vkpr kong install --mode="standard" --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/service-kong-admin.yaml kong/kong --version $VKPR_KONG_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  tail -n +2 $BATS_FILE_TMPDIR/temp.yaml > $BATS_FILE_TMPDIR/manifest.yaml
  csplit $BATS_FILE_TMPDIR/manifest.yaml '/\-\-\-/' -f $BATS_FILE_TMPDIR/manifest.yaml -n "0" | mv -f $BATS_FILE_TMPDIR/manifest.yaml1 $BATS_FILE_TMPDIR/manifest.yaml | rm -f $BATS_FILE_TMPDIR/manifest.yaml0  
  
  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "true"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "api.manager.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "admin-kong-cert"
}

# bats test_tags=input_secure, input_secure:default
@test "check secure default" {

  rit vkpr kong install --mode="standard" --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/service-kong-admin.yaml kong/kong --version $VKPR_KONG_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  tail -n +2 $BATS_FILE_TMPDIR/temp.yaml > $BATS_FILE_TMPDIR/manifest.yaml
  csplit $BATS_FILE_TMPDIR/manifest.yaml '/\-\-\-/' -f $BATS_FILE_TMPDIR/manifest.yaml -n "0" | mv -f $BATS_FILE_TMPDIR/manifest.yaml1 $BATS_FILE_TMPDIR/manifest.yaml | rm -f $BATS_FILE_TMPDIR/manifest.yaml0  
  
  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "null"
}

#------#
# MODE #
#------#

@test "check kong-mode flag" {

  export VKPR_ENV_KONG_MODE="dbless"
  run $VKPR_YQ -i ".kong.mode = \"dbless\"" $PWD/vkpr.yaml
  assert_success

  rit vkpr kong install --mode='standard' \
     --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  local KONG_MODE_CONTENT=$($VKPR_YQ ".env.database" $BATS_FILE_TMPDIR/values.yaml)
  run echo $KONG_MODE_CONTENT
  assert_output "postgres"
}

@test "check kong-mode file" {

  export VKPR_ENV_KONG_MODE="dbless"
  run $VKPR_YQ -i ".kong.mode = \"standard\"" $PWD/vkpr.yaml
  assert_success

  rit vkpr kong install \
     --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  local KONG_MODE_CONTENT=$($VKPR_YQ ".env.database" $BATS_FILE_TMPDIR/values.yaml)
  run echo $KONG_MODE_CONTENT
  assert_output "postgres"
}

@test "check kong-mode env" {

  export VKPR_ENV_KONG_MODE="standard"

  rit vkpr kong install \
     --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  local KONG_MODE_CONTENT=$($VKPR_YQ ".env.database" $BATS_FILE_TMPDIR/values.yaml)
  run echo $KONG_MODE_CONTENT
  assert_output "postgres"
}

#--------------#
# LICENSE PATH #
#--------------#

@test "check kong-license flag" {

  export VKPR_ENV_KONG_ENTERPRISE_LICENSE=""
  run $VKPR_YQ -i ".kong.enterprise.license = \"\"" $PWD/vkpr.yaml
  assert_success

  echo 'flag' > $BATS_FILE_TMPDIR/license
  local FLAG_LICENSE="$BATS_FILE_TMPDIR/license"

  rit vkpr kong install --mode="standard" \
    --license=$FLAG_LICENSE --dry_run \
    | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  local LICENSE_CONTENT=$($VKPR_YQ ".data.license" kong-enterprise-license.yaml | base64 -d)
  run echo $LICENSE_CONTENT
  assert_output "flag"

  # rm $BATS_FILE_TMPDIR/license
}

@test "check kong-license file" {

  export VKPR_ENV_KONG_ENTERPRISE_LICENSE=""
  run $VKPR_YQ -i ".kong.enterprise.license = \"$BATS_FILE_TMPDIR/license\"" $PWD/vkpr.yaml
  assert_success

  echo 'file' > $BATS_FILE_TMPDIR/license

  rit vkpr kong install --mode="standard" --dry_run \
    | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  local LICENSE_CONTENT=$($VKPR_YQ ".data.license" kong-enterprise-license.yaml | base64 -d)
  run echo $LICENSE_CONTENT
  assert_output "file"

  # rm $BATS_FILE_TMPDIR/license
}
@test "check kong-license env" {
 
  export VKPR_ENV_KONG_ENTERPRISE_LICENSE="$BATS_FILE_TMPDIR/license"

  echo 'env' > $BATS_FILE_TMPDIR/license

  rit vkpr kong install --mode="standard" \
    --license=$FLAG_LICENSE --dry_run \
    | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  local LICENSE_CONTENT=$($VKPR_YQ ".data.license" kong-enterprise-license.yaml | base64 -d)
  run echo $LICENSE_CONTENT
  assert_output "env"

  # rm $BATS_FILE_TMPDIR/license
  # unset VKPR_ENV_KONG_ENTERPRISE_LICENSE
}

@test "check kong-license default" {
  
  rit vkpr kong install --mode="standard" \
    --default --dry_run \
    | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  local LICENSE_CONTENT=$($VKPR_YQ ".data.license" kong-enterprise-license.yaml | base64 -d)
  run echo $LICENSE_CONTENT
  assert_output ""
}

#---------------#
# RBAC PASSWORD #
#---------------#

@test "check kong-RBAC flag" {

  export VKPR_ENV_KONG_RBAC_ADMIN_PASSWORD="env1234"
  run $VKPR_YQ -i ".kong.rbac.adminPassword = \"file123\"" $PWD/vkpr.yaml
  assert_success

  rit vkpr kong install --mode="standard" --rbac_password="flag123" \
  --default --dry_run \
  | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  local LICENSE_CONTENT=$($VKPR_YQ ".data.password" kong-enterprise-superuser-password.yaml | base64 -d)

  run echo $LICENSE_CONTENT
  assert_output "flag123"
}

@test "check kong-RBAC file" {
  export VKPR_ENV_KONG_RBAC_ADMIN_PASSWORD="env1234"
  run $VKPR_YQ -i ".kong.rbac.adminPassword = \"file123\"" $PWD/vkpr.yaml
  assert_success

  rit vkpr kong install --mode="standard" \
  --default --dry_run \
  | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  local LICENSE_CONTENT=$($VKPR_YQ ".data.password" kong-enterprise-superuser-password.yaml | base64 -d)

  run echo $LICENSE_CONTENT
  assert_output "file123"
}

@test "check kong-RBAC env" {
  export VKPR_ENV_KONG_RBAC_ADMIN_PASSWORD="env1234"

  rit vkpr kong install --mode="standard" \
  --default --dry_run \
  | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  local LICENSE_CONTENT=$($VKPR_YQ ".data.password" kong-enterprise-superuser-password.yaml | base64 -d)

  run echo $LICENSE_CONTENT
  assert_output "env1234"
}

@test "check kong-RBAC default" {

  rit vkpr kong install --mode="standard" \
  --default --dry_run \
  | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  local LICENSE_CONTENT=$($VKPR_YQ ".data.password" kong-enterprise-superuser-password.yaml | base64 -d)

  run echo $LICENSE_CONTENT
  assert_output "vkpr123"
}

#------#
#  HA  #
#------#

# bats test_tags=input_HA, input_HA:flag
@test "check kong-HA flag" {
  export VKPR_ENV_KONG_HA="false"
  run $VKPR_YQ -i ".kong.HA = \"false\"" $PWD/vkpr.yaml
  assert_success

  rit vkpr kong install --mode="standard" --HA --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/hpa.yaml kong/kong --version $VKPR_KONG_VERSION > $BATS_FILE_TMPDIR/manifest.yaml
  
  local KIND=$($VKPR_YQ ".kind" $BATS_FILE_TMPDIR/manifest.yaml)
  run echo $KIND
  assert_output "HorizontalPodAutoscaler"

  local MIN_REPL=$($VKPR_YQ ".spec.minReplicas" $BATS_FILE_TMPDIR/manifest.yaml)
  run echo $MIN_REPL
  assert_output "3"

  local MAX_REPL=$($VKPR_YQ ".spec.maxReplicas" $BATS_FILE_TMPDIR/manifest.yaml)
  run echo $MAX_REPL
  assert_output "5"
}

# bats test_tags=input_HA, input_HA:file
@test "check kong-HA file" {
  export VKPR_ENV_KONG_HA="false"
  run $VKPR_YQ -i ".kong.HA = \"true\"" $PWD/vkpr.yaml
  assert_success

  rit vkpr kong install --mode="standard" --HA --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/hpa.yaml kong/kong --version $VKPR_KONG_VERSION > $BATS_FILE_TMPDIR/manifest.yaml
  
  local KIND=$($VKPR_YQ ".kind" $BATS_FILE_TMPDIR/manifest.yaml)
  run echo $KIND
  assert_output "HorizontalPodAutoscaler"

  local MIN_REPL=$($VKPR_YQ ".spec.minReplicas" $BATS_FILE_TMPDIR/manifest.yaml)
  run echo $MIN_REPL
  assert_output "3"

  local MAX_REPL=$($VKPR_YQ ".spec.maxReplicas" $BATS_FILE_TMPDIR/manifest.yaml)
  run echo $MAX_REPL
  assert_output "5"
}

# bats test_tags=input_HA, input_HA:env
@test "check kong-HA env" {
  export VKPR_ENV_KONG_HA="true"

  rit vkpr kong install --mode="standard" --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/hpa.yaml kong/kong --version $VKPR_KONG_VERSION > $BATS_FILE_TMPDIR/manifest.yaml
  
  local KIND=$($VKPR_YQ ".kind" $BATS_FILE_TMPDIR/manifest.yaml)
  run echo $KIND
  assert_output "HorizontalPodAutoscaler"

  local MIN_REPL=$($VKPR_YQ ".spec.minReplicas" $BATS_FILE_TMPDIR/manifest.yaml)
  run echo $MIN_REPL
  assert_output "3"

  local MAX_REPL=$($VKPR_YQ ".spec.maxReplicas" $BATS_FILE_TMPDIR/manifest.yaml)
  run echo $MAX_REPL
  assert_output "5"
}

# bats test_tags=input_HA, input_HA:default
@test "check kong-HA default" {

  rit vkpr kong install --mode="standard" --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  
  run helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/hpa.yaml kong/kong --version $VKPR_KONG_VERSION > $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "Error: could not find template templates/hpa.yaml in chart"
}

#-------------#
#  HELM ARGS  #
#-------------#

@test "check helmArgs adding new value" {
  $VKPR_YQ -i ".kong.helmArgs.admin.ingress.annotations.[\"teste\"] = \"Prefix\"" $PWD/vkpr.yaml

  rit vkpr kong install --mode="standard" --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/service-kong-admin.yaml kong/kong --version $VKPR_KONG_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  tail -n +2 $BATS_FILE_TMPDIR/temp.yaml > $BATS_FILE_TMPDIR/manifest.yaml
  csplit $BATS_FILE_TMPDIR/manifest.yaml '/\-\-\-/' -f $BATS_FILE_TMPDIR/manifest.yaml -n "0" | mv -f $BATS_FILE_TMPDIR/manifest.yaml1 $BATS_FILE_TMPDIR/manifest.yaml | rm -f $BATS_FILE_TMPDIR/manifest.yaml0  

  run $VKPR_YQ ".metadata.annotations.[\"teste\"]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "Prefix"
}

@test "check helmArgs changing values" {
  $VKPR_YQ -i ".kong.helmArgs.admin.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"false\"" $PWD/vkpr.yaml

  rit vkpr kong install --mode="standard" --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/service-kong-admin.yaml kong/kong --version $VKPR_KONG_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  tail -n +2 $BATS_FILE_TMPDIR/temp.yaml > $BATS_FILE_TMPDIR/manifest.yaml
  csplit $BATS_FILE_TMPDIR/manifest.yaml '/\-\-\-/' -f $BATS_FILE_TMPDIR/manifest.yaml -n "0" | mv -f $BATS_FILE_TMPDIR/manifest.yaml1 $BATS_FILE_TMPDIR/manifest.yaml | rm -f $BATS_FILE_TMPDIR/manifest.yaml0  
  cat $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "false"
}

#=======================================#
#         INSTALLATION SECTION          #
#=======================================#

@test "check application health" {

  local KONG_STATUS_HELM=$($VKPR_HELM ls -n vkpr | grep kong | tr -s '[:space:]' ' ' | cut -d " " -f8 )

  run echo $KONG_STATUS_HELM
  assert_output "deployed"

  kong_status=$($VKPR_KUBECTL get po -n vkpr | grep -i "Running" | grep -i kong | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $kong_status 
  assert_output "2/2"
}

@test "hit application health" {

  run curl -LIsw "%{http_code}" -o /dev/null http://manager.localhost:8000
  assert_output "200"
}

@test "hit postgresql database " {
  
  local POSTGRES_STATUS_CONECTION=$($VKPR_KUBECTL exec -it postgres-postgresql-0 -n vkpr -- pg_isready -U "postgres" -d "dbname=postgres" -h 127.0.0.1 -p 5432) \
        POSTGRES_STATUS_HELM=$($VKPR_HELM ls -n vkpr | grep postgresql | tr -s '[:space:]' ' ' | cut -d " " -f8 )

  run echo $POSTGRES_STATUS_CONECTION
  assert_output -p "127.0.0.1:5432 - accepting connections"

  run echo $POSTGRES_STATUS_HELM
  assert_output "deployed"
}

#=======================================#
#            OBJECT SECTION             #
#=======================================#

  #----------#
  #  Secret  #
  #----------#

  # kong-enterprise-license
@test "check kong-enterprise-license" {
  kong_secret_name=$($VKPR_KUBECTL get secret -n vkpr | grep kong-enterprise-license | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $kong_secret_name 
  assert_output "kong-enterprise-license"

  kong_secret_type=$($VKPR_KUBECTL get secret -n vkpr | grep kong-enterprise-license | tr -s '[:space:]' ' ' | cut -d " " -f3)
  run echo $kong_secret_type 
  assert_output "1"
}

  # postgres-postgresql
@test "check postgres-postgresql" {
  kong_service_name=$($VKPR_KUBECTL get secret -n vkpr | grep postgres-postgresql | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $kong_service_name 
  assert_output "postgres-postgresql"

  kong_service_type=$($VKPR_KUBECTL get secret -n vkpr | grep postgres-postgresql | tr -s '[:space:]' ' ' | cut -d " " -f3)
  run echo $kong_service_type 
  assert_output "1"
}
  # kong-enterprise-superuser-password
@test "check kong-enterprise-superuser-password" {
  kong_secret_name=$($VKPR_KUBECTL get secret -n vkpr | grep kong-enterprise-superuser-password | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $kong_secret_name 
  assert_output "kong-enterprise-superuser-password"

  kong_secret_type=$($VKPR_KUBECTL get secret -n vkpr | grep kong-enterprise-superuser-password | tr -s '[:space:]' ' ' | cut -d " " -f3)
  run echo $kong_secret_type 
  assert_output "1"
}

  # kong-session-config
@test "check kong-session-config" {
  kong_secret_name=$($VKPR_KUBECTL get secret -n vkpr | grep kong-session-config | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $kong_secret_name 
  assert_output "kong-session-config"

  kong_secret_type=$($VKPR_KUBECTL get secret -n vkpr | grep kong-session-config | tr -s '[:space:]' ' ' | cut -d " " -f3)
  run echo $kong_secret_type 
  assert_output "2"
}

  # kong-kong-token
@test "check kong-kong-token" {
  kong_secret_name=$($VKPR_KUBECTL get secret -n vkpr | grep kong-kong-token | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $kong_secret_name 
  assert_output "kong-kong-token"

  kong_secret_type=$($VKPR_KUBECTL get secret -n vkpr | grep kong-kong-token | tr -s '[:space:]' ' ' | cut -d " " -f3)
  run echo $kong_secret_type 
  assert_output "3"
}

@test "check kong sh.helm.release.v1.kong.v1" {
  # sh.helm.release.v1.kong.v1
  kong_secret_name=$($VKPR_KUBECTL get secret -n vkpr | grep sh.helm.release.v1.kong.v1 | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $kong_secret_name 
  assert_output "sh.helm.release.v1.kong.v1"

  kong_secret_type=$($VKPR_KUBECTL get secret -n vkpr | grep sh.helm.release.v1.kong.v1 | tr -s '[:space:]' ' ' | cut -d " " -f3)
  run echo $kong_secret_type 
  assert_output "1"
}

@test "check kong sh.helm.release.v1.postgresql.v1" {
  # sh.helm.release.v1.postgresql.v1
  kong_secret_name=$($VKPR_KUBECTL get secret -n vkpr | grep sh.helm.release.v1.postgresql.v1 | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $kong_secret_name 
  assert_output "sh.helm.release.v1.postgresql.v1"

  kong_secret_type=$($VKPR_KUBECTL get secret -n vkpr | grep sh.helm.release.v1.postgresql.v1 | tr -s '[:space:]' ' ' | cut -d " " -f3)
  run echo $kong_secret_type 
  assert_output "1"
}
  #-----------#
  #  Service  #
  #-----------#

  # kong-kong-admin
@test "check kong-kong-admin" {
  kong_service_name=$($VKPR_KUBECTL get svc -n vkpr | grep kong-kong-admin | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $kong_service_name 
  assert_output "kong-kong-admin"

  kong_service_type=$($VKPR_KUBECTL get svc -n vkpr | grep kong-kong-admin | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $kong_service_type 
  assert_output "ClusterIP"
}

  # kong-kong-manager
@test "check kong-kong-manager" {
  kong_service_name=$($VKPR_KUBECTL get svc -n vkpr | grep kong-kong-manager | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $kong_service_name 
  assert_output "kong-kong-manager"

  kong_service_type=$($VKPR_KUBECTL get svc -n vkpr | grep kong-kong-manager | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $kong_service_type 
  assert_output "ClusterIP"
}
  # kong-kong-proxy
@test "check kong-kong-proxy" {
  kong_service_name=$($VKPR_KUBECTL get svc -n vkpr | grep kong-kong-proxy | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $kong_service_name 
  assert_output "kong-kong-proxy"

  kong_service_type=$($VKPR_KUBECTL get svc -n vkpr | grep kong-kong-proxy | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $kong_service_type 
  assert_output "LoadBalancer"

}

#=======================================#
#         INTEGRATION SECTION           #
#=======================================#

#-----------#
#   whoami  #
#-----------#

@test "curl to whoami.localhost:8000 with HTTP" {
  
  run $VKPR_YQ -i ".whoami.ingressClassName = \"kong\"" $PWD/vkpr.yaml
  assert_success
  rit vkpr whoami install --default

  local i=0 \
      timeout=5 \

  while [[ $i -lt $timeout ]]; do
    if curl -is http://whoami.localhost:8000 | head -n1 | awk -F' ' '{print $2}' | grep -q "200"; then
      break
    else
      sleep 1
      i=$((i+1))
    fi
  done

  RESPONSE=$(curl -is http://whoami.localhost:8000 | head -n1 | awk -F' ' '{print $2}')
  run echo $RESPONSE
  assert_output "200"
  assert_success

  $VKPR_YQ -i "del(.global) | del(.whoami)" $PWD/vkpr.yaml
}
  #----------------------#
  #   prometheus-stack   #
  #----------------------#

# validating kong as ingress and metrics
@test "curl to prometheus.localhost:8000 with HTTP" {
  
  run $VKPR_YQ -i ".prometheus-stack.ingressClassName = \"kong\"" $PWD/vkpr.yaml
  assert_success
  rit vkpr prometheus-stack install --default
  
  # enabling metrics for service monitoring
  run $VKPR_YQ -i ".kong.metrics = \"true\"" $PWD/vkpr.yaml
  assert_success
  rit vkpr kong install --default

  local i=0 \
      timeout=10 \

  while [[ $i -lt $timeout ]]; do
    if curl -is http://manager.localhost:8000 | head -n1 | awk -F' ' '{print $2}' | grep -q "200"; then
      break
    else
      sleep 1
      i=$((i+1))
    fi
  done

  RESPONSE=$(curl -is http://prometheus.localhost:8000/api/v1 | head -n1 | awk -F' ' '{print $2}')
  run echo $RESPONSE
  assert_output "301"
  assert_success

  
  $VKPR_YQ -i "del(.global) | del(.prometheus-stack) | del(.kong)" $PWD/vkpr.yaml
}

# validating kong metrics: true
@test "curl to prometheus API endpoint to kong_datastore metric" {
 
  RESPONSE=$(curl -i prometheus.localhost:8000/api/v1/query?query=kong_datastore_reachable | head -n1 | awk -F' ' '{print $2}')

  run echo $RESPONSE
  assert_output "200"
  assert_success

  RESPONSE=$(curl prometheus.localhost:8000/api/v1/query?query=kong_datastore_reachable | jq .status)

  run echo $RESPONSE
  assert_output "\"success\""
  assert_success

}
@test "check kong dashboard grafana status" {

  LOGIN_GRAFANA=$($VKPR_KUBECTL get secret --namespace vkpr prometheus-stack-grafana -o=jsonpath="{.data.admin-user}" | base64 -d)
  PWD_GRAFANA=$($VKPR_KUBECTL get secret --namespace vkpr prometheus-stack-grafana -o=jsonpath="{.data.admin-password}" | base64 -d)

  RESPONSE=$(curl http://$LOGIN_GRAFANA:$PWD_GRAFANA@grafana.localhost:8000/api/dashboards/tags | jq '.[] | select(.term == "vkpr-kong")')

  run echo $RESPONSE
  assert_output '{ "term": "vkpr-kong", "count": 1 }'
  assert_success 
}