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
    echo "setup: installing cert-manager..." >&3
    rit vkpr cert-manager install digitalocean --issuer="staging" --issuer_solver="HTTP01" --default
  fi
}

@test "Create a certificates to issue with applications" {
  rit vkpr whoami install --domain="vkpr-test.com" --secure
  sleep 10
  $VKPR_KUBECTL get challenge -n vkpr | grep -q whoami-cert
  assert_success
}

@test "Use vkpr.yaml to merge values in cert-manager with helmArgs" {
  testValue="cert-manager"
  useVKPRfile changeYAMLfile ".cert-manager.helmArgs.fullnameOverride = \"${testValue}\""
  sleep 10

  run $VKPR_HELM get values cert-manager -n cert-manager
  assert_line --partial "fullnameOverride: cert-manager"
  assert_success
}

teardown_file() {
  if [ "$VKPR_TEST_SKIP_TEARDOWN" == "true" ]; then
    echo "teardown: skipping uninstall due to VKPR_TEST_SKIP_TEARDOWN=true" >&3
  else
    echo "teardown: uninstalling cert-manager..." >&3
    rit vkpr cert-manager remove
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
  $VKPR_YQ eval -i "del(.cert-manager)" vkpr.yaml
  $VKPR_YQ eval "${1}" vkpr.yaml > vkpr.yaml
  rit vkpr cert-manager install digitalocean "$2" --issuer="staging" --issuer_solver="HTTP01" --default
}
