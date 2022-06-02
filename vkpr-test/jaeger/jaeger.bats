setup() {
  load $VKPR_HOME/bats/bats-support/load.bash
  load $VKPR_HOME/bats/bats-assert/load.bash
}

setup_file() {
  load '../.bats/common.bats.bash'
  _common_setup

  if [ "$VKPR_TEST_SKIP_PROVISIONING" == "true" ]; then
    echo "setup: skipping provisionig due to VKPR_TEST_SKIP_PROVISIONING=true" >&3
  else
    echo "setup: installing ingress..." >&3
    rit vkpr ingress install --default
    echo "setup: installing jaeger..." >&3
    rit vkpr jaeger install --default
  fi
}

@test "wget to Jaeger with HTTP" {
  sleep 10
  run wget -qO- http://jaeger.localhost:8000/

  assert_success
}

@test "Use vkpr.yaml to merge values in Jaeger with helmArgs" {
  testValue="jaeger-test"
  useVKPRfile changeYAMLfile ".jaeger.helmArgs.fullnameOverride = \"${testValue}\" |
    .jaeger.helmArgs.query.basePath = \"/test\"
  "
  sleep 10

  run $VKPR_HELM get values jaeger -n vkpr
  assert_line --partial "fullnameOverride: jaeger-test"
  assert_success
}

@test "Use vkpr.yaml to change values in Jaeger with globals" {
  useVKPRfile changeYAMLfile ".global.namespace = \"vtg\" |
    .jaeger.namespace = \"vkpr\"
  "
  sleep 10

  run $VKPR_HELM ls -A -o=json | $VKPR_JQ -r '.[] | select(.name | contains("jaeger"))'

  refute_line --partial "\"namespace\":\"vtg\""
  assert_success
}

teardown_file() {
  if [ "$VKPR_TEST_SKIP_TEARDOWN" == "true" ]; then
    echo "teardown: skipping uninstall due to VKPR_TEST_SKIP_TEARDOWN=true" >&3
  else
    echo "teardown: uninstalling jaeger..." >&3
    rit vkpr jaeger remove
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
  $VKPR_YQ eval -i "del(.jaeger)" vkpr.yaml
  $VKPR_YQ eval "${1}" vkpr.yaml > vkpr.yaml
  rit vkpr jaeger install $2 --default
}
