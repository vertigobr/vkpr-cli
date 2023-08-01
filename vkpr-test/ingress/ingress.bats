#!/usr/bin/env bats

# ~/.vkpr/bats/bin/bats vkpr-test/ingress/ingress.bats

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
    echo "setup: installing ingress..." >&3
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
    echo "Uninstall kong" >&3
    rit vkpr ingress remove
  fi

  _common_teardown
}

teardown() {
  $VKPR_YQ -i "del(.global) | del(.ingress)" $PWD/vkpr.yaml
}

@test "curl to nGINX with HTTP and must return status 404" {
  run curl -I http://localhost:8000
  assert_output --partial "HTTP/1.1 404 Not Found"
  assert_success
}

@test "curl to nGINX with HTTPs and must return status 404" {
  run curl -kI  https://localhost:8001
  assert_output --partial "HTTP/2 404"
  assert_success
}

@test "Use vkpr.yaml to merge values in ingress with helmArgs" {
  testValue="nginx-test"
  useVKPRfile changeYAMLfile ".ingress.helmArgs.controller.labels.[\"app.kubernetes.io/tested-by\"] = \"${testValue}\"" 
  sleep 10

  run $VKPR_HELM get values ingress -n vkpr
  assert_line --partial "nginx-test"
  assert_success
}

@test "Use vkpr.yaml to change values in ingress with globals" {
  useVKPRfile changeYAMLfile ".global.namespace = \"vtg\" |
    .ingress.namespace = \"vkpr\"
  "
  sleep 10

  run $VKPR_HELM ls -A -o=json | $VKPR_JQ -r '.[] | select(.name | contains("ingress-nginx"))'

  refute_line --partial "\"namespace\":\"vtg\""
  assert_success
}

teardown_file() {
  if [ "$VKPR_TEST_SKIP_TEARDOWN" == "true" ]; then
    echo "teardown: skipping uninstall due to VKPR_TEST_SKIP_TEARDOWN=true" >&3
  else
    echo "teardown: uninstalling ingress..." >&3
    rit vkpr ingress remove
  fi

  _common_teardown
}

useVKPRfile() {
  cp vkpr.yaml vkpr.yaml.tmp
  "$@"
  mv vkpr.yaml.tmp vkpr.yaml
}

#PARAMETERS:
# $1 - YQ_VALUES
# $2 - FORMULA_FLAGS (Optional)
changeYAMLfile() {
  $VKPR_YQ eval -i "del(.ingress)" vkpr.yaml
  $VKPR_YQ eval "${1}" vkpr.yaml > vkpr.yaml
  rit vkpr ingress install $2 --default
}
