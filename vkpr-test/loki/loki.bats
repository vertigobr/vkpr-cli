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
    echo "setup: installing loki..." >&3
    rit vkpr loki install --default
  fi
}

@test "curl to Loki must return ready" {
  expected=$($VKPR_KUBECTL run --namespace vkpr --wait --rm -it \
    --restart=Never --image=curlimages/curl curl \
    --command -- curl -sH "Content-Type: application/json" http://loki-stack:3100/ready
  )
  run echo "$expected"

  assert_line --partial "ready"
}

@test "Use vkpr.yaml to merge values in loki with helmArgs" {
  testValue="loki-test"
  useVKPRfile changeYAMLfile ".loki.helmArgs.fullnameOverride = \"${testValue}\" |
    .loki.helmArgs.ingress.hosts[0].paths[0] = \"/test\"
  "
  sleep 10

  run $VKPR_HELM get values loki-stack -n vkpr
  assert_line --partial "fullnameOverride: loki-test"
  assert_success
}

@test "Use vkpr.yaml to change values in loki with globals" {
  useVKPRfile changeYAMLfile ".global.namespace = \"vtg\" |
    .loki.namespace = \"vkpr\"
  "
  sleep 10

  run $VKPR_HELM ls -A -o=json | $VKPR_JQ -r '.[] | select(.name | contains("loki"))'

  refute_line --partial "\"namespace\":\"vtg\""
  assert_success
}

teardown_file() {
  if [ "$VKPR_TEST_SKIP_TEARDOWN" == "true" ]; then
    echo "teardown: skipping teardown due to VKPR_TEST_SKIP_TEARDOWN=true" >&3
  else
    echo "teardown: uninstalling loki..." >&3
    rit vkpr loki remove
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
  $VKPR_YQ eval -i "del(.loki)" vkpr.yaml
  $VKPR_YQ eval "${1}" vkpr.yaml > vkpr.yaml
  rit vkpr loki install $2 --default
}