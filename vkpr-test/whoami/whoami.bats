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
  fi
}

@test "wget to Whoami with HTTP and must return Hostname" {
  rit vkpr whoami install --default
  sleep 10
  run wget -qO- http://whoami.localhost:8000/

  assert_line --partial "Host: whoami.localhost:8000"
  assert_line --partial "X-Scheme: http"
  assert_success
}

@test "wget to Whoami with HTTPS and must return Hostname" {
  rit vkpr whoami install --secure="true" --default
  sleep 10
  run wget --no-check-certificate -qO- https://whoami.localhost:8001/

  assert_line --partial "Host: whoami.localhost:8001"
  assert_line --partial "X-Scheme: https"
  assert_success
}

@test "Use vkpr.yaml to merge values in Whoami with helmArgs" {
  testValue="whoami-test"
  useVKPRfile changeYAMLfile ".whoami.helmArgs.fullnameOverride = \"${testValue}\" |
    .whoami.helmArgs.ingress.hosts[0].paths[0] = \"/test\"
  "
  sleep 10

  run $VKPR_HELM get values whoami -n vkpr
  assert_line --partial "fullnameOverride: whoami-test"
  assert_success
}

@test "Use vkpr.yaml to change values in Whoami with globals" {
  useVKPRfile changeYAMLfile ".global.namespace = \"vtg\" |
    .whoami.namespace = \"vkpr\"
  "
  sleep 10

  run $VKPR_HELM ls -A -o=json | $VKPR_JQ -r '.[] | select(.name | contains("whoami"))'

  refute_line --partial "\"namespace\":\"vtg\""
  assert_success
}

teardown_file() {
  if [ "$VKPR_TEST_SKIP_TEARDOWN" == "true" ]; then
    echo "teardown: skipping uninstall due to VKPR_TEST_SKIP_TEARDOWN=true" >&3
  else
    echo "teardown: uninstalling whoami..." >&3
    rit vkpr whoami remove
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
  $VKPR_YQ eval -i "del(.whoami)" vkpr.yaml
  $VKPR_YQ eval "${1}" vkpr.yaml > vkpr.yaml
  rit vkpr whoami install $2 --default
}
