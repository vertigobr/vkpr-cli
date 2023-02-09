#!/usr/bin/env bats

# ~/.vkpr/bats/bin/bats vkpr-test/loki/loki.bats

export DETIK_CLIENT_NAMESPACE="vkpr"
load '../.bats/common.bats'


setup_file() {
  touch $PWD/vkpr.yaml

  [ "$VKPR_TEST_SKIP_ALL" == "true" ] && echo "common_setup: skipping common_setup due to VKPR_TEST_SKIP_ALL=true" >&3 && return
  _common_setup "1" "false" "1"

  if [ "$VKPR_TEST_SKIP_DEPLOY_ACTIONS" == "true" ]; then
    echo "setup: skipping provisionig due to VKPR_TEST_SKIP_PROVISIONING=true" >&3
  else
    echo "setup: installing ingress..." >&3
    rit vkpr ingress install --default
    echo "setup: installing loki..." >&3
    rit vkpr loki install --default
  fi
}

teardown_file() {
  if [ "$VKPR_TEST_SKIP_ALL" == "true" ]; then
    echo "teardown: skipping uninstall due to VKPR_TEST_SKIP_ALL=true" >&3
    return
  fi

  if [ "$VKPR_TEST_SKIP_DEPLOY_ACTIONS" == "true" ]; then
    echo "common_setup: skipping common_setup due to VKPR_TEST_SKIP_DEPLOY_ACTIONS=true" >&3
  else
    echo "teardown: uninstalling loki..." >&3
    rit vkpr loki remove
    echo "teardown: uninstalling ingress..." >&3
    rit vkpr ingress remove
  fi

  _common_teardown
}

teardown() {
  $VKPR_YQ -i "del(.global) | del(.loki)" $PWD/vkpr.yaml
}

#=======================================#
#         INSTALLATION SECTION          #
#=======================================#

@test "curl to Loki must return ready" {
  expected=$($VKPR_KUBECTL run --namespace vkpr --rm -it \
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

##########INPUTS#########

@test useVKPRfile() {
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

#-------------#
#  HELM ARGS  #
#-------------#

# bats test_tags=helm_args, helm_args:new
@test "check helmArgs adding new value" {
  $VKPR_YQ -i ".loki.helmArgs.ingress.PathType = \"Prefix\"" $PWD/vkpr.yaml

  rit vkpr loki install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s charts/grafana/templates/ingress.yaml prometheus-community/kube-loki --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/manifest.yaml
  cat $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".spec.rules[0].http.paths[0].pathType" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "Prefix"
}

# bats test_tags=helm_args, helm_args:change
@test "check helmArgs changing values" {
  $VKPR_YQ -i ".loki.helmArgs.grafana.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"false\"" $PWD/vkpr.yaml

  rit vkpr loki install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s charts/grafana/templates/ingress.yaml prometheus-community/kube-loki --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/manifest.yaml
  cat $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "false"
}

### CHECK CREATE LOKI ###
@test "check loki create" {
    run  kubectl get pod -n vkpr loki-0 |grep Running 
    #assert_output --partial "Running"
}
@test "check loki running" {
curl -s "http://localhost:3100/loki/api/v1/series" --data-urlencode 'match[]={container_name=~"prometheus.*", component="server"}' --data-urlencode 'match[]={app="loki"}' | jq '.'
}