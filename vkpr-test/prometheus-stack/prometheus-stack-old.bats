setup() {
  load $VKPR_HOME/bats/bats-support/load.bash
  load $VKPR_HOME/bats/bats-assert/load.bash
  export TOKEN_API_GRAFANA
}

setup_file() {
  load '../.bats/common.bats.bash'
  _common_setup

  if [ "$VKPR_TEST_SKIP_PROVISIONING" == "true" ]; then
    echo "setup: skipping provisionig due to VKPR_TEST_SKIP_PROVISIONING=true" >&3
  else
    echo "setup: installing ingress..." >&3
    rit vkpr ingress install --default
    echo "setup: installing prometheus-stack..." >&3
    rit vkpr prometheus-stack install --default
  fi
}

@test "Check if prometheus datasource is ready" {
  TOKEN_API_GRAFANA=$(curl -skX POST \
    -H "Host: grafana.localhost" -H "Content-Type: application/json" \
    -d '{"name": "apikeycurl'$RANDOM'","role": "Admin", "secondsToLive": 20}' \
    http://admin:vkpr123@127.0.0.1:8000/api/auth/keys | $VKPR_JQ --raw-output '.key' -
  )

  run curl -sK -X GET -H "Host: grafana.localhost" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TOKEN_API_GRAFANA" \
    http://127.0.0.1:8000/api/datasources
  sleep 20

  assert_line --partial "\"name\":\"Prometheus\""
  assert_success
}

@test "Check if loki datasource is ready" {
  rit vkpr loki install --default
  TOKEN_API_GRAFANA=$(curl -skX POST \
    -H "Host: grafana.localhost" -H "Content-Type: application/json" \
    -d '{"name": "apikeycurl'$RANDOM'","role": "Admin", "secondsToLive": 20}' \
    http://admin:vkpr123@127.0.0.1:8000/api/auth/keys | $VKPR_JQ --raw-output '.key' -
  )

  run curl -sK -X GET -H "Host: grafana.localhost" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TOKEN_API_GRAFANA" \
    http://127.0.0.1:8000/api/datasources
  sleep 20

  assert_line --partial "\"name\":\"loki\""
  assert_success
}

@test "Use vkpr.yaml to merge values in prometheus-stack with helmArgs" {
  testValue="prometheus-stack-test"
  useVKPRfile changeYAMLfile ".prometheus-stack.helmArgs.fullnameOverride = \"${testValue}\" |
    .prometheus-stack.helmArgs.grafana.ingress.path = \"/test\"
  "
  sleep 10

  run $VKPR_HELM get values prometheus-stack -n vkpr
  assert_line --partial "fullnameOverride: prometheus-stack-test"
  assert_success
}

@test "Use vkpr.yaml to change values in prometheus-stack with globals" {
  useVKPRfile changeYAMLfile ".global.namespace = \"vtg\" |
    .prometheus-stack.namespace = \"vkpr\"
  "
  sleep 10

  run $VKPR_HELM ls -A -o=json | $VKPR_JQ -r '.[] | select(.name | contains("prometheus-stack"))'

  refute_line --partial "\"namespace\":\"vtg\""
  assert_success
}

teardown_file() {
  if [ "$VKPR_TEST_SKIP_TEARDOWN" == "true" ]; then
    echo "teardown: skipping uninstall due to VKPR_TEST_SKIP_TEARDOWN=true" >&3
  else
    echo "teardown: uninstalling prometheus-stack..." >&3
    rit vkpr prometheus-stack remove
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
  $VKPR_YQ eval -i "del(.prometheus-stack)" vkpr.yaml
  $VKPR_YQ eval "${1}" vkpr.yaml > vkpr.yaml
  rit vkpr prometheus-stack install $2 --default
}
