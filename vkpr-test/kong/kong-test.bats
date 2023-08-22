#!/usr/bin/env bats

# ~/.vkpr/bats/bin/bats vkpr-test/kong/kong-test.bats

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

#===========================================================================================================================================#

@test "check secret creation kong-enterprise-license" {
  export FIRST_REPO="$(rit list repo | tail -n +2 | head -n3 | awk -F' ' '{print $2}' | tr '\n' ' ' | column -t | awk -F' ' '{print $1}')"
  source ~/.rit/repos/$FIRST_REPO/vkpr/kong/install/src/unix/formula/objects.sh

  echo 'content' > $BATS_FILE_TMPDIR/license
  export VKPR_ENV_KONG_ENTERPRISE_LICENSE=$BATS_FILE_TMPDIR/license
  export VKPR_ENVIRONMENT=local
  export VKPR_ENV_KONG_NAMESPACE="vkpr"
  export DRY_RUN=false

  $VKPR_KUBECTL delete secret/kong-enterprise-license -n $VKPR_ENV_KONG_NAMESPACE && \
  sleep 1
  createKongSecretsEnterprise 
  
  SECRET_STATUS="$($VKPR_KUBECTL get secret/kong-enterprise-license -n $VKPR_ENV_KONG_NAMESPACE | tail -n +2 | awk -F' ' '{print $1}')"
  run echo $SECRET_STATUS
  assert_output "kong-enterprise-license"
}

@test "check kong-license content" {
  export VKPR_ENV_KONG_ENTERPRISE_LICENSE=""
  run $VKPR_YQ -i ".kong.enterprise.license = \"\"" $PWD/vkpr.yaml
  assert_success

  echo 'content' > $BATS_FILE_TMPDIR/license
  local PATH_LICENSE="$BATS_FILE_TMPDIR/license"

  rit vkpr kong install --mode="standard" \
    --license=$PATH_LICENSE > /dev/null 2>&1

  local LICENSE_CONTENT="$($VKPR_KUBECTL get secret/kong-enterprise-license -n vkpr -o=yaml | $VKPR_YQ '.data.license' | base64 -d)"
  run echo $LICENSE_CONTENT
  assert_output "content"
  rm $BATS_FILE_TMPDIR/license
}

@test "check helmArgs adding new value" {
  $VKPR_YQ -i ".kong.helmArgs.admin.ingress.annotations.[\"teste\"] = \"Prefix\"" $PWD/vkpr.yaml

  rit vkpr kong install --mode="standard" --default --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/service-kong-admin.yaml kong/kong --version $VKPR_KONG_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  
  run $VKPR_YQ "select(documentIndex == 1).metadata.annotations.[\"teste\"]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "Prefix"
}

@test "check kong-kong-token" {
  kong_secret_name=$($VKPR_KUBECTL get secret -n vkpr | grep kong-kong-token | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $kong_secret_name 
  assert_output "kong-kong-token"

  kong_secret_type=$($VKPR_KUBECTL get secret -n vkpr | grep kong-kong-token | tr -s '[:space:]' ' ' | cut -d " " -f3)
  run echo $kong_secret_type 
  assert_output "3"
}

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