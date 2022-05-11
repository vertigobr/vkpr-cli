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
    echo "setup: installing argocd..." >&3
    rit vkpr argocd install --default
  fi
}

@test "Create a session using the generated password" {
  argo_password=$($VKPR_KUBECTL get secret/argocd-initial-admin-secret -o=jsonpath="{.data.password}" -n argocd | base64 -d)
  curl -H "Host: argocd.localhost" http://127.0.0.1:8000/api/v1/session \
    -d '{"username":"admin","password":"$argo_password"}'
  
  refute_line --partial "null"
  assert_success
}

@test "Use vkpr.yaml to merge values in argocd with helmArgs" {
  testValue="argocd-test"
  useVKPRfile changeYAMLfile ".argocd.helmArgs.fullnameOverride = \"${testValue}\" |
    .argocd.helmArgs.server.ingress.paths[0] = \"/test\"
  "
  sleep 10

  run $VKPR_HELM get values argocd -n argocd
  assert_line --partial "fullnameOverride: argocd-test"
  assert_success
}

@test "Use vkpr.yaml to change values in argocd with globals" {
  useVKPRfile changeYAMLfile ".global.namespace = \"vtg\" |
    .argocd.namespace = \"vkpr\"
  "
  sleep 10

  run $VKPR_HELM ls -A -o=json | $VKPR_JQ -r '.[] | select(.name | contains("argocd"))'

  refute_line --partial "\"namespace\":\"vtg\""
  assert_success
}

teardown_file() {
  if [ "$VKPR_TEST_SKIP_TEARDOWN" == "true" ]; then
    echo "teardown: skipping uninstall due to VKPR_TEST_SKIP_TEARDOWN=true" >&3
  else
    echo "teardown: uninstalling argocd..." >&3
    rit vkpr argocd remove
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
  $VKPR_YQ eval -i "del(.argocd)" vkpr.yaml
  $VKPR_YQ eval "${1}" vkpr.yaml > vkpr.yaml
  rit vkpr argocd install $2 --default
}
