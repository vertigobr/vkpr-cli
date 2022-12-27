#!/usr/bin/env bats

# ~/.vkpr/bats/bin/bats vkpr-test/prometheus-stack/prometheus-stack.bats

export DETIK_CLIENT_NAMESPACE="vkpr"
load '../.bats/common.bats'

setup() {
  load "$VKPR_HOME/bats/bats-support/load"
  load "$VKPR_HOME/bats/bats-assert/load"
  load "$VKPR_HOME/bats/bats-detik/load"
  load "$VKPR_HOME/bats/bats-file/load"
  export TOKEN_API_GRAFANA
}

setup_file() {
  touch $PWD/vkpr.yaml

  [ "$VKPR_TEST_SKIP_ALL" == "true" ] && echo "common_setup: skipping common_setup due to VKPR_TEST_SKIP_ALL=true" >&3 && return
  _common_setup "1" "false" "1"

  if [ "$VKPR_TEST_SKIP_DEPLOY_ACTIONS" == "true" ]; then
    echo "setup: skipping provisionig due to VKPR_TEST_SKIP_PROVISIONING=true" >&3
  else
    echo "setup: installing ingress..." >&3
    rit vkpr ingress install --default
    echo "setup: installing prometheus-stack..." >&3
    rit vkpr prometheus-stack install --default
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
    echo "teardown: uninstalling prometheus-stack..." >&3
    rit vkpr prometheus-stack remove
    echo "teardown: uninstalling ingress..." >&3
    rit vkpr ingress remove
  fi

  _common_teardown
}

teardown() {
  $VKPR_YQ -i "del(.global) | del(.prometheus-stack)" $PWD/vkpr.yaml
}

#=======================================#
#           INPUTS SECTION              #
#=======================================#

#--------#
# DOMAIN #
#--------#
        
# bats test_tags=input_domain, input_domain:flag
@test "check domain flag" {
  export VKPR_ENV_GLOBAL_DOMAIN="env.net"
  run $VKPR_YQ -i ".global.domain = \"config.net\"" $PWD/vkpr.yaml
  assert_success

  rit vkpr prometheus-stack install --domain=input.net --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/prometheus/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "prometheus.input.net"

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s charts/grafana/templates/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "grafana.input.net"
}

# bats test_tags=input_domain, input_domain:file
@test "check domain file" {
  export VKPR_ENV_GLOBAL_DOMAIN="env.net"
  run $VKPR_YQ -i ".global.domain = \"config.net\"" $PWD/vkpr.yaml
  assert_success

  rit vkpr prometheus-stack install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/prometheus/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "prometheus.config.net"

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s charts/grafana/templates/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "grafana.config.net"
}

# bats test_tags=input_domain, input_domain:env
@test "check domain env" {
  export VKPR_ENV_GLOBAL_DOMAIN="env.net"

  rit vkpr prometheus-stack install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/prometheus/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "prometheus.env.net"

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s charts/grafana/templates/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "grafana.env.net"
}

# bats test_tags=input_domain, input_domain:default
@test "check domain default" {

  rit vkpr prometheus-stack install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/prometheus/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  
  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "prometheus.localhost"

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s charts/grafana/templates/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "grafana.localhost"
}

#--------#
# SECURE #
#--------#

# bats test_tags=input_secure, input_secure:flag
@test "check secure flag" {
  export VKPR_ENV_GLOBAL_SECURE="true"
  run $VKPR_YQ -i ".global.secure = false" $PWD/vkpr.yaml
  assert_success

  rit vkpr prometheus-stack install --secure --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/prometheus/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml
    
  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "true"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "prometheus.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "prometheus-cert"

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s charts/grafana/templates/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  
  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "true"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "grafana.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "grafana-cert"
}

# bats test_tags=input_secure, input_secure:file
@test "check secure file" {
  export VKPR_ENV_GLOBAL_SECURE="true"
  run $VKPR_YQ -i ".global.secure = false" $PWD/vkpr.yaml
  assert_success

  rit vkpr prometheus-stack install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/prometheus/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml
    
  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "null"

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s charts/grafana/templates/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  
  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "null"
  }

# bats test_tags=input_secure, input_secure:env
@test "check secure env" {
  export VKPR_ENV_GLOBAL_SECURE="true"

  rit vkpr prometheus-stack install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/prometheus/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml
    
  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "true"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "prometheus.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "prometheus-cert"

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s charts/grafana/templates/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  
  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "true"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "grafana.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "grafana-cert"

}

# bats test_tags=input_secure, input_secure:default
@test "check secure default" {

  rit vkpr prometheus-stack install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/prometheus/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml
    
  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "null"

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s charts/grafana/templates/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  
  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "null"
}

#------------------------#
# GRAFANA ADMIN PASSWORD #
#------------------------#

# bats test_tags=admin-password, admin-password:flag
@test "check admin-password flag" {
  export VKPR_ENV_GRAFANA_PASSWORD="env1234"
  run $VKPR_YQ -i ".prometheus-stack.grafana.adminPassword = \"file123\"" $PWD/vkpr.yaml
  assert_success

  rit vkpr prometheus-stack install --grafana_password="flag123" > /dev/null 2>&1
  kubectl get -n vkpr -o=yaml secret/prometheus-stack-grafana > $BATS_FILE_TMPDIR/GRAFANA_PASSWORD.yaml

  local SECRET_CONTENT="$($VKPR_YQ ".data.admin-password" $BATS_FILE_TMPDIR/GRAFANA_PASSWORD.yaml | base64 -d)"

  run echo $SECRET_CONTENT
  assert_output "flag123"
}

# bats test_tags=admin-password, admin-password:file
@test "check admin-password file" {
  export VKPR_ENV_GRAFANA_PASSWORD="env1234"
  run $VKPR_YQ -i ".prometheus-stack.grafana.adminPassword = \"file123\"" $PWD/vkpr.yaml
  assert_success

  rit vkpr prometheus-stack install --default > /dev/null 2>&1
  kubectl get -n vkpr -o=yaml secret/prometheus-stack-grafana > $BATS_FILE_TMPDIR/GRAFANA_PASSWORD.yaml

  local SECRET_CONTENT="$($VKPR_YQ ".data.admin-password" $BATS_FILE_TMPDIR/GRAFANA_PASSWORD.yaml | base64 -d)"

  run echo $SECRET_CONTENT
  assert_output "file123"
}
# bats test_tags=admin-password, admin-password:env
@test "check admin-password env" {
  export VKPR_ENV_GRAFANA_PASSWORD="env1234"

  rit vkpr prometheus-stack install --default > /dev/null 2>&1
  kubectl get -n vkpr -o=yaml secret/prometheus-stack-grafana > $BATS_FILE_TMPDIR/GRAFANA_PASSWORD.yaml

  local SECRET_CONTENT="$($VKPR_YQ ".data.admin-password" $BATS_FILE_TMPDIR/GRAFANA_PASSWORD.yaml | base64 -d)"

  run echo $SECRET_CONTENT
  assert_output "env1234"
}
# bats test_tags=admin-password, admin-password:default
@test "check admin-password default" {

  rit vkpr prometheus-stack install --default > /dev/null 2>&1
  kubectl get -n vkpr -o=yaml secret/prometheus-stack-grafana > $BATS_FILE_TMPDIR/GRAFANA_PASSWORD.yaml

  local SECRET_CONTENT="$($VKPR_YQ ".data.admin-password" $BATS_FILE_TMPDIR/GRAFANA_PASSWORD.yaml | base64 -d)"

  run echo $SECRET_CONTENT
  assert_output "vkpr123"
}

#------------------------#
#      Alert-Manager     #
#------------------------#

# bats test_tags=alertmanager, alertmanager:flag
@test "check alertManager flag" {
  export VKPR_ENV_ALERTMANAGER="false"
  run $VKPR_YQ -i ".prometheus-stack.alertManager.enabled = false" $PWD/vkpr.yaml
  assert_success

  rit vkpr prometheus-stack install --alertmanager --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/alertmanager/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "alertmanager.localhost"
}

# bats test_tags=alertmanager, alertmanager:file
@test "check alertManager file" {
  export VKPR_ENV_ALERTMANAGER="false"
  run $VKPR_YQ -i ".prometheus-stack.alertManager.enabled = true" $PWD/vkpr.yaml
  assert_success

  rit vkpr prometheus-stack install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/alertmanager/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "alertmanager.localhost"
}

# bats test_tags=alertmanager, alertmanager:env
@test "check alertManager env" {
  export VKPR_ENV_ALERTMANAGER="true"

  rit vkpr prometheus-stack install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/alertmanager/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "alertmanager.localhost"
}

#------#
#  HA  #
#------#

# bats test_tags=input_HA, input_HA:flag

@test "check prometheus-stack-HA flag" {
  export VKPR_ENV_PROMETHEUS_STACK_HA="false" 
  run $VKPR_YQ -i ".prometheus-stack.HA = \"false\"" $PWD/vkpr.yaml
  assert_success

  $VKPR_YQ -i ".prometheus-stack.alertManager.enabled = \"true\"" $PWD/vkpr.yaml
  rit vkpr prometheus-stack install --HA --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/alertmanager/alertmanager.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  local NUM_REPL=$($VKPR_YQ ".spec.replicas" $BATS_FILE_TMPDIR/temp.yaml)
  run echo $NUM_REPL
  assert_output "3"
  local TIME_RETENTION=$($VKPR_YQ ".spec.retention" $BATS_FILE_TMPDIR/temp.yaml)
  run echo $TIME_RETENTION
  assert_output "1d"

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/prometheus/prometheus.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  local NUM_REPL=$($VKPR_YQ ".spec.replicas" $BATS_FILE_TMPDIR/temp.yaml)
  run echo $NUM_REPL
  assert_output "3"
  local TIME_RETENTION=$($VKPR_YQ ".spec.retention" $BATS_FILE_TMPDIR/temp.yaml)
  run echo $TIME_RETENTION
  assert_output "90d"
}

# bats test_tags=input_HA, input_HA:file
@test "check prometheus-stack-HA file" {
  export VKPR_ENV_PROMETHEUS_STACK_HA="false" 
  run $VKPR_YQ -i ".prometheus-stack.HA = \"true\"" $PWD/vkpr.yaml
  assert_success

  $VKPR_YQ -i ".prometheus-stack.alertManager.enabled = \"true\"" $PWD/vkpr.yaml
  rit vkpr prometheus-stack install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/alertmanager/alertmanager.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  local NUM_REPL=$($VKPR_YQ ".spec.replicas" $BATS_FILE_TMPDIR/temp.yaml)
  run echo $NUM_REPL
  assert_output "3"
  local TIME_RETENTION=$($VKPR_YQ ".spec.retention" $BATS_FILE_TMPDIR/temp.yaml)
  run echo $TIME_RETENTION
  assert_output "1d"

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/prometheus/prometheus.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  local NUM_REPL=$($VKPR_YQ ".spec.replicas" $BATS_FILE_TMPDIR/temp.yaml)
  run echo $NUM_REPL
  assert_output "3"
  local TIME_RETENTION=$($VKPR_YQ ".spec.retention" $BATS_FILE_TMPDIR/temp.yaml)
  run echo $TIME_RETENTION
  assert_output "90d"

}

# bats test_tags=input_HA, input_HA:env
@test "check prometheus-stack-HA env" {
  export VKPR_ENV_PROMETHEUS_STACK_HA="true" 

  $VKPR_YQ -i ".prometheus-stack.alertManager.enabled = \"true\"" $PWD/vkpr.yaml
  rit vkpr prometheus-stack install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/alertmanager/alertmanager.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  local NUM_REPL=$($VKPR_YQ ".spec.replicas" $BATS_FILE_TMPDIR/temp.yaml)
  run echo $NUM_REPL
  assert_output "3"
  local TIME_RETENTION=$($VKPR_YQ ".spec.retention" $BATS_FILE_TMPDIR/temp.yaml)
  run echo $TIME_RETENTION
  assert_output "1d"

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/prometheus/prometheus.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  local NUM_REPL=$($VKPR_YQ ".spec.replicas" $BATS_FILE_TMPDIR/temp.yaml)
  run echo $NUM_REPL
  assert_output "3"
  local TIME_RETENTION=$($VKPR_YQ ".spec.retention" $BATS_FILE_TMPDIR/temp.yaml)
  run echo $TIME_RETENTION
  assert_output "90d"

}

# bats test_tags=input_HA, input_HA:default
@test "check prometheus-stack-HA default" {

  $VKPR_YQ -i ".prometheus-stack.alertManager.enabled = \"true\"" $PWD/vkpr.yaml
  rit vkpr prometheus-stack install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/alertmanager/alertmanager.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  local NUM_REPL=$($VKPR_YQ ".spec.replicas" $BATS_FILE_TMPDIR/temp.yaml)
  run echo $NUM_REPL
  assert_output "1"
  local TIME_RETENTION=$($VKPR_YQ ".spec.retention" $BATS_FILE_TMPDIR/temp.yaml)
  run echo $TIME_RETENTION
  assert_output "120h"

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/prometheus/prometheus.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/temp.yaml
  local NUM_REPL=$($VKPR_YQ ".spec.replicas" $BATS_FILE_TMPDIR/temp.yaml)
  run echo $NUM_REPL
  assert_output "1"
  local TIME_RETENTION=$($VKPR_YQ ".spec.retention" $BATS_FILE_TMPDIR/temp.yaml)
  run echo $TIME_RETENTION
  assert_output "10d"
}
#-----#
# SSL #
#-----#

# bats test_tags=input_ssl, input_ssl:flag
@test "check SSL flag" {
  createFileSSL

  export VKPR_ENV_GRAFANA_SSL="true" \
    VKPR_ENV_GRAFANA_SSL_CERTIFICATE="$BATS_FILE_TMPDIR/server.crt" \
    VKPR_ENV_GRAFANA_SSL_KEY="$BATS_FILE_TMPDIR/server.key"

  $VKPR_YQ -i ".prometheus-stack.grafana.ssl.enabled = false |
   .prometheus-stack.grafana.ssl.crt = \"$BATS_FILE_TMPDIR/server.crt\" |
   .prometheus-stack.grafana.ssl.key = \"$BATS_FILE_TMPDIR/server.key\"" $PWD/vkpr.yaml

  rit vkpr prometheus-stack install \
    --ssl --crt_file="$BATS_FILE_TMPDIR/server.crt" --key_file="$BATS_FILE_TMPDIR/server.key" --dry_run \
    | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s charts/grafana/templates/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/manifest.yaml
  cat $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "grafana.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "grafana-certificate"

  crt_b64=$(cat $BATS_FILE_TMPDIR/server.crt | base64 -w0)
  key_b64=$(cat $BATS_FILE_TMPDIR/server.key | base64 -w0)

  run $VKPR_YQ ".data.\"tls.crt\"" grafana-certificate.yaml
  assert_output "$crt_b64"
  run $VKPR_YQ ".data.\"tls.key\"" grafana-certificate.yaml
  assert_output "$key_b64"
}

# bats test_tags=input_ssl, input_ssl:file
@test "check SSL file" {
  createFileSSL

  export VKPR_ENV_GRAFANA_SSL="false" \
    VKPR_ENV_GRAFANA_SSL_CERTIFICATE="$BATS_FILE_TMPDIR/server.crt" \
    VKPR_ENV_GRAFANA_SSL_KEY="$BATS_FILE_TMPDIR/server.key"

  $VKPR_YQ -i ".prometheus-stack.grafana.ssl.enabled = true |
   .prometheus-stack.grafana.ssl.crt = \"$BATS_FILE_TMPDIR/server.crt\" |
   .prometheus-stack.grafana.ssl.key = \"$BATS_FILE_TMPDIR/server.key\"" $PWD/vkpr.yaml

  rit vkpr prometheus-stack install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s charts/grafana/templates/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/manifest.yaml
  cat $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "grafana.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "grafana-certificate"

  crt_b64=$(cat $BATS_FILE_TMPDIR/server.crt | base64 -w0)
  key_b64=$(cat $BATS_FILE_TMPDIR/server.key | base64 -w0)

  run $VKPR_YQ ".data.\"tls.crt\"" grafana-certificate.yaml
  assert_output "$crt_b64"
  run $VKPR_YQ ".data.\"tls.key\"" grafana-certificate.yaml
  assert_output "$key_b64"
}

# bats test_tags=input_ssl, input_ssl:env
@test "check SSL env" {
  createFileSSL

  export VKPR_ENV_GRAFANA_SSL="true" \
    VKPR_ENV_GRAFANA_SSL_CERTIFICATE="$BATS_FILE_TMPDIR/server.crt" \
    VKPR_ENV_GRAFANA_SSL_KEY="$BATS_FILE_TMPDIR/server.key"

  rit vkpr prometheus-stack install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s charts/grafana/templates/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/manifest.yaml
  cat $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "grafana.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "grafana-certificate"

  crt_b64=$(cat $BATS_FILE_TMPDIR/server.crt | base64 -w0)
  key_b64=$(cat $BATS_FILE_TMPDIR/server.key | base64 -w0)

  run $VKPR_YQ ".data.\"tls.crt\"" grafana-certificate.yaml
  assert_output "$crt_b64"
  run $VKPR_YQ ".data.\"tls.key\"" grafana-certificate.yaml
  assert_output "$key_b64"

}

# bats test_tags=input_ssl, input_ssl:default
@test "check SSL default" {

  rit vkpr prometheus-stack install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s charts/grafana/templates/ingress.yaml prometheus-community/kube-prometheus-stack --version $VKPR_PROMETHEUS_STACK_VERSION > $BATS_FILE_TMPDIR/manifest.yaml
  cat $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "null"
  
}

#=======================================#
#         INTEGRATION SECTION           #
#=======================================#

createFileSSL() {
  openssl genrsa -out $BATS_FILE_TMPDIR/server.key 2048
  openssl rsa -in $BATS_FILE_TMPDIR/server.key -out $BATS_FILE_TMPDIR/server.key
  openssl req -sha256 -new -key $BATS_FILE_TMPDIR/server.key -out $BATS_FILE_TMPDIR/server.csr -subj '/CN=localhost'
  openssl x509 -req -sha256 -days 365 -in $BATS_FILE_TMPDIR/server.csr -signkey $BATS_FILE_TMPDIR/server.key -out $BATS_FILE_TMPDIR/server.crt
}