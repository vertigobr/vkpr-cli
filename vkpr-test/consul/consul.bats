setup() {
  load $VKPR_HOME/bats/bats-support/load.bash
  load $VKPR_HOME/bats/bats-assert/load.bash
}

setup_file() {
  load '../.bats/common.bats.bash'
  _common_setup "--worker_nodes 2"

  if [ "$VKPR_TEST_SKIP_PROVISIONING" == "true" ]; then
    echo "setup: skipping provisionig due to VKPR_TEST_SKIP_PROVISIONING=true" >&3
  else
    echo "setup: installing ingress..." >&3
    rit vkpr ingress install --default
    echo "setup: installing consul..." >&3
    rit vkpr consul install --default
  fi
}

@test "wget to consul with HTTP and must return Hostname" {
  run wget -qO- http://consul.localhost:8000/v1/health/node/consul-consul-server-0
  sleep 20

  assert_line --partial "passing"
  assert_success
}

@test "Use vkpr.yaml to merge values in Consul with helmArgs" {
  testValue="consul-test"
  useVKPRfile changeYAMLfile ".consul.helmArgs.fullnameOverride = \"${testValue}\" |
    .consul.helmArgs.ui.ingress.hosts[0].paths[0] = \"/test\"
  "
  sleep 10

  run $VKPR_HELM get values consul -n vkpr
  assert_line --partial "fullnameOverride: consul-test"
  assert_success
}

@test "Use vkpr.yaml to change values in Consul with globals" {
  useVKPRfile changeYAMLfile ".global.namespace = \"vtg\" |
    .consul.namespace = \"vkpr\"
  "
  sleep 10

  run $VKPR_HELM ls -A -o=json | $VKPR_JQ -r '.[] | select(.name | contains("consul"))'

  refute_line --partial "\"namespace\":\"vtg\""
  assert_success
}

teardown_file() {
  if [ "$VKPR_TEST_SKIP_TEARDOWN" == "true" ]; then
    echo "teardown: skipping uninstall due to VKPR_TEST_SKIP_TEARDOWN=true" >&3
  else
    echo "teardown: uninstalling consul..." >&3
    rit vkpr consul remove
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
  $VKPR_YQ eval -i "del(.consul)" vkpr.yaml
  $VKPR_YQ eval "${1}" vkpr.yaml > vkpr.yaml
  rit vkpr consul install $2 --default
}
