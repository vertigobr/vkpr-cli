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
    echo "setup: installing vault..." >&3
    #rit vkpr vault install --default
  fi
}

@test "Use vkpr.yaml to merge values in vault with helmArgs" {
  testValue="vault-test"
  useVKPRfile changeYAMLfile ".vault.helmArgs.fullnameOverride = \"${testValue}\" |
    .vault.helmArgs.server.ingress.hosts[0].path = \"/test\"
  "
  sleep 10

  run $VKPR_HELM get values vault -n vkpr
  assert_line --partial "fullnameOverride: vault-test"
  assert_success
}

@test "Use vkpr.yaml to change values in vault with globals" {
  useVKPRfile changeYAMLfile ".global.namespace = \"vtg\" |
    .vault.namespace = \"vkpr\"
  "
  sleep 10

  run $VKPR_HELM ls -A -o=json | $VKPR_JQ -r '.[] | select(.name | contains("vault"))'

  refute_line --partial "\"namespace\":\"vtg\""
  assert_success
}

teardown_file() {
  if [ "$VKPR_TEST_SKIP_TEARDOWN" == "true" ]; then
    echo "teardown: skipping uninstall due to VKPR_TEST_SKIP_TEARDOWN=true" >&3
  else
    echo "teardown: uninstalling vault..." >&3
    rit vkpr vault remove
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
  $VKPR_YQ eval -i "del(.vault)" vkpr.yaml
  $VKPR_YQ eval "${1}" vkpr.yaml > vkpr.yaml
  rit vkpr vault install $2 --default
}
