#!/usr/bin/env bats

# ~/.vkpr/bats/bin/bats vkpr-test/jaeger/jaeger.bats

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
    echo "setup: installing jaeger..." >&3
    rit vkpr jaeger install --default
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
    echo "teardown: uninstalling jaeger..." >&3
    rit vkpr jaeger remove
    echo "teardown: uninstalling ingress..." >&3
    rit vkpr ingress remove
  fi

  _common_teardown
}

teardown() {
  $VKPR_YQ -i "del(.global) | del(.jaeger)" $PWD/vkpr.yaml
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
  
  rit vkpr jaeger install --domain=input.net --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/query-ing.yaml jaegertracing/jaeger --version $VKPR_JAEGER_VERSION  > $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "jaeger.input.net"
}

# bats test_tags=input_domain, input_domain:file
@test "check domain file" {
  export VKPR_ENV_GLOBAL_DOMAIN="env.net"
  run $VKPR_YQ -i ".global.domain = \"config.net\"" $PWD/vkpr.yaml
  assert_success

  rit vkpr jaeger install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/query-ing.yaml jaegertracing/jaeger --version $VKPR_JAEGER_VERSION  > $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "jaeger.config.net"
}

# bats test_tags=input_domain, input_domain:env
@test "check domain env" {
  export VKPR_ENV_GLOBAL_DOMAIN="env.net"

  rit vkpr jaeger install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/query-ing.yaml jaegertracing/jaeger --version $VKPR_JAEGER_VERSION  > $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "jaeger.env.net"
}

# bats test_tags=input_domain, input_domain:default
@test "check domain default" {

  rit vkpr jaeger install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/query-ing.yaml jaegertracing/jaeger --version $VKPR_JAEGER_VERSION  > $BATS_FILE_TMPDIR/temp.yaml

  run $VKPR_YQ ".spec.rules[0].host" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "jaeger.localhost"
}

#--------#
# SECURE #
#--------#

# bats test_tags=input_secure, input_secure:flag
@test "check secure flag" {
  export VKPR_ENV_GLOBAL_SECURE="true"
  run $VKPR_YQ -i ".global.secure = false" $PWD/vkpr.yaml
  assert_success

  rit vkpr jaeger install --secure --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/query-ing.yaml jaegertracing/jaeger --version $VKPR_JAEGER_VERSION  > $BATS_FILE_TMPDIR/temp.yaml
    
  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "true"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "jaeger.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "jaeger-cert"
}

# bats test_tags=input_secure, input_secure:file
@test "check secure file" {
  export VKPR_ENV_GLOBAL_SECURE="true"
  run $VKPR_YQ -i ".global.secure = false" $PWD/vkpr.yaml
  assert_success

  rit vkpr jaeger install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/query-ing.yaml jaegertracing/jaeger --version $VKPR_JAEGER_VERSION  > $BATS_FILE_TMPDIR/temp.yaml
    
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

  rit vkpr jaeger install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/query-ing.yaml jaegertracing/jaeger --version $VKPR_JAEGER_VERSION  > $BATS_FILE_TMPDIR/temp.yaml
    
  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "true"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "jaeger.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "jaeger-cert"
}

# bats test_tags=input_secure, input_secure:default
@test "check secure default" {

  rit vkpr jaeger install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/query-ing.yaml jaegertracing/jaeger --version $VKPR_JAEGER_VERSION  > $BATS_FILE_TMPDIR/temp.yaml
    
  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/temp.yaml
  assert_output "null"
}


#-----#
# SSL #
#-----#

# bats test_tags=input_ssl, input_ssl:flag
@test "check SSL flag" {
  createFileSSL

  export VKPR_ENV_JAEGER_SSL="true" \
    VKPR_ENV_JAEGER_SSL_CERTIFICATE="$BATS_FILE_TMPDIR/server.crt" \
    VKPR_ENV_JAEGER_SSL_KEY="$BATS_FILE_TMPDIR/server.key"

  $VKPR_YQ -i ".jaeger.ssl.enabled = false |
   .jaeger.ssl.crt = \"$BATS_FILE_TMPDIR/server.crt\" |
   .jaeger.ssl.key = \"$BATS_FILE_TMPDIR/server.key\"" $PWD/vkpr.yaml

  rit vkpr jaeger install \
    --ssl --crt_file="$BATS_FILE_TMPDIR/server.crt" --key_file="$BATS_FILE_TMPDIR/server.key" --dry_run \
    | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/query-ing.yaml jaegertracing/jaeger --version $VKPR_JAEGER_VERSION > $BATS_FILE_TMPDIR/manifest.yaml
  cat $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "jaeger.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "vkpr/jaeger-certificate"

  crt_b64=$(cat $BATS_FILE_TMPDIR/server.crt | base64 -w0)
  key_b64=$(cat $BATS_FILE_TMPDIR/server.key | base64 -w0)

  run $VKPR_YQ ".data.\"tls.crt\"" jaeger-certificate.yaml
  assert_output "$crt_b64"
  run $VKPR_YQ ".data.\"tls.key\"" jaeger-certificate.yaml
  assert_output "$key_b64"
}

# bats test_tags=input_ssl, input_ssl:file
@test "check SSL file" {
  createFileSSL

  export VKPR_ENV_JAEGER_SSL="false" \
    VKPR_ENV_JAEGER_SSL_CERTIFICATE="$BATS_FILE_TMPDIR/server.crt" \
    VKPR_ENV_JAEGER_SSL_KEY="$BATS_FILE_TMPDIR/server.key"

  $VKPR_YQ -i ".jaeger.ssl.enabled = true |
   .jaeger.ssl.crt = \"$BATS_FILE_TMPDIR/server.crt\" |
   .jaeger.ssl.key = \"$BATS_FILE_TMPDIR/server.key\"" $PWD/vkpr.yaml

  rit vkpr jaeger install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/query-ing.yaml jaegertracing/jaeger --version $VKPR_JAEGER_VERSION > $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "jaeger.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "vkpr/jaeger-certificate"

  crt_b64=$(cat $BATS_FILE_TMPDIR/server.crt | base64 -w0)
  key_b64=$(cat $BATS_FILE_TMPDIR/server.key | base64 -w0)

  run $VKPR_YQ ".data.\"tls.crt\"" jaeger-certificate.yaml
  assert_output "$crt_b64"
  run $VKPR_YQ ".data.\"tls.key\"" jaeger-certificate.yaml
  assert_output "$key_b64"
}

# bats test_tags=input_ssl, input_ssl:env
@test "check SSL env" {
  createFileSSL

  export VKPR_ENV_JAEGER_SSL="true" \
    VKPR_ENV_JAEGER_SSL_CERTIFICATE="$BATS_FILE_TMPDIR/server.crt" \
    VKPR_ENV_JAEGER_SSL_KEY="$BATS_FILE_TMPDIR/server.key"

  rit vkpr jaeger install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/query-ing.yaml jaegertracing/jaeger --version $VKPR_JAEGER_VERSION > $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "jaeger.localhost"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "vkpr/jaeger-certificate"

  crt_b64=$(cat $BATS_FILE_TMPDIR/server.crt | base64 -w0)
  key_b64=$(cat $BATS_FILE_TMPDIR/server.key | base64 -w0)

  run $VKPR_YQ ".data.\"tls.crt\"" jaeger-certificate.yaml
  assert_output "$crt_b64"
  run $VKPR_YQ ".data.\"tls.key\"" jaeger-certificate.yaml
  assert_output "$key_b64"
}

# bats test_tags=input_ssl, input_ssl:default
@test "check SSL default" {

  rit vkpr jaeger install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1

  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/query-ing.yaml jaegertracing/jaeger --version $VKPR_JAEGER_VERSION > $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".spec.tls[0].hosts[0]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "null"
  run $VKPR_YQ ".spec.tls[0].secretName" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "null"
  
}

#-------------#
#  HELM ARGS  #
#-------------#

# bats test_tags=helm_args, helm_args:new
@test "check helmArgs adding new value" {
  $VKPR_YQ -i ".jaeger.helmArgs.query.ingress.annotations[\"app.kubernetes.io/managed-by\"] = \"vkpr\"" $PWD/vkpr.yaml

  rit vkpr jaeger install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/query-ing.yaml jaegertracing/jaeger --version $VKPR_JAEGER_VERSION > $BATS_FILE_TMPDIR/manifest.yaml
  cat $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".metadata.annotations[\"app.kubernetes.io/managed-by\"]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "vkpr"
}

# bats test_tags=helm_args, helm_args:change
@test "check helmArgs changing values" {
  $VKPR_YQ -i ".jaeger.helmArgs.query.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"false\"" $PWD/vkpr.yaml

  rit vkpr jaeger install --dry_run | tee $BATS_FILE_TMPDIR/values.yaml > /dev/null 2>&1
  helm template -f $BATS_FILE_TMPDIR/values.yaml -s templates/query-ing.yaml jaegertracing/jaeger --version $VKPR_JAEGER_VERSION > $BATS_FILE_TMPDIR/manifest.yaml
  cat $BATS_FILE_TMPDIR/manifest.yaml

  run $VKPR_YQ ".metadata.annotations.[\"kubernetes.io/tls-acme\"]" $BATS_FILE_TMPDIR/manifest.yaml
  assert_output "false"
}


#=======================================#
#         INSTALLATION SECTION          #
#=======================================#

@test "check application health" {

  local i=0 \
  timeout=500 \

  while [[ $i -lt $timeout ]]; do
    if $VKPR_KUBECTL get po -n vkpr | grep -i "Running" | grep -i "jaeger-cassandra-2" | tr -s '[:space:]' ' ' | cut -d " " -f2 | grep -q "1/1"; then
      if $VKPR_KUBECTL get po -n vkpr | grep -i "Running" | grep -i "jaeger-cassandra-1" | tr -s '[:space:]' ' ' | cut -d " " -f2 | grep -q "1/1"; then      
        if $VKPR_KUBECTL get po -n vkpr | grep -i "Running" | grep -i "jaeger-cassandra-0" | tr -s '[:space:]' ' ' | cut -d " " -f2 | grep -q "1/1"; then      
          break
        fi
      fi
    fi
      sleep 1
      i=$((i+1))
  done

  local JAEGER_STATUS_HELM=$($VKPR_HELM ls -n vkpr | grep jaeger | tr -s '[:space:]' ' ' | cut -d " " -f8 )

  run echo $JAEGER_STATUS_HELM
  assert_output "deployed"

  jaeger_status=$($VKPR_KUBECTL get po -n vkpr | grep -i "Running" | grep -i jaeger-agent | head -n 1 | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $jaeger_status 
  assert_output "1/1"

  jaeger_status=$($VKPR_KUBECTL get po -n vkpr | grep -i "Running" | grep -i jaeger-agent | tail -n 1 |  tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $jaeger_status 
  assert_output "1/1"

  jaeger_status=$($VKPR_KUBECTL get po -n vkpr | grep -i "Running" | grep -i jaeger-query | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $jaeger_status 
  assert_output "2/2"

  jaeger_status=$($VKPR_KUBECTL get po -n vkpr | grep -i "Running" | grep -i jaeger-collector | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $jaeger_status 
  assert_output "1/1"

  jaeger_status=$($VKPR_KUBECTL get po -n vkpr | grep -i "Running" | grep -i jaeger-cassandra-0 | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $jaeger_status 
  assert_output "1/1"

  jaeger_status=$($VKPR_KUBECTL get po -n vkpr | grep -i "Running" | grep -i jaeger-cassandra-1 | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $jaeger_status 
  assert_output "1/1"

  jaeger_status=$($VKPR_KUBECTL get po -n vkpr | grep -i "Running" | grep -i jaeger-cassandra-2 | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $jaeger_status 
  assert_output "1/1"

  jaeger_status=$($VKPR_KUBECTL get po -n vkpr | grep -i "Completed" | grep -i jaeger-cassandra-schema | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $jaeger_status 
  assert_output "0/1"
}

@test "hit application health" {

  RESPONSE=$(curl -is http://jaeger.localhost:8000/search | head -n1 | awk -F' ' '{print $2}')
  run echo $RESPONSE
  assert_output "200"
}

#=======================================#
#            OBJECT SECTION             #
#=======================================#

  #----------#
  #  Secret  #
  #----------#

  # jaeger-cassandra
@test "check jaeger-cassandra secret" {
  jaeger_secret_name=$($VKPR_KUBECTL get secret -n vkpr | grep jaeger-cassandra | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $jaeger_secret_name 
  assert_output "jaeger-cassandra"

  jaeger_secret_name=$($VKPR_KUBECTL get secret -n vkpr | grep jaeger-cassandra | tr -s '[:space:]' ' ' | cut -d " " -f3)
  run echo $jaeger_secret_name 
  assert_output "1"
}

  # sh.helm.release.v1.jaeger.v1
@test "check sh.helm.release.v1.jaeger.v1 secret" {
  prometheus_secret_name=$($VKPR_KUBECTL get secret -n vkpr | grep sh.helm.release.v1.jaeger.v1 | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $prometheus_secret_name 
  assert_output "sh.helm.release.v1.jaeger.v1"

  prometheus_secret_data=$($VKPR_KUBECTL get secret -n vkpr | grep sh.helm.release.v1.jaeger.v1 | tr -s '[:space:]' ' ' | cut -d " " -f3)
  run echo $prometheus_secret_data 
  assert_output "1"
}

  #-----------#
  #  Service  #
  #-----------#

  # jaeger-cassandra
@test "check jaeger-cassandra service" {
  prometheus_service_name=$($VKPR_KUBECTL get svc -n vkpr | grep jaeger-cassandra | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $prometheus_service_name 
  assert_output "jaeger-cassandra"

  prometheus_service_type=$($VKPR_KUBECTL get svc -n vkpr | grep jaeger-cassandra | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $prometheus_service_type 
  assert_output "ClusterIP"
}

  # jaeger-agent
@test "check jaeger-agent service" {
  prometheus_service_name=$($VKPR_KUBECTL get svc -n vkpr | grep jaeger-agent | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $prometheus_service_name 
  assert_output "jaeger-agent"

  prometheus_service_type=$($VKPR_KUBECTL get svc -n vkpr | grep jaeger-agent | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $prometheus_service_type 
  assert_output "ClusterIP"
}

  # jaeger-query
@test "check jaeger-query service" {
  prometheus_service_name=$($VKPR_KUBECTL get svc -n vkpr | grep jaeger-query | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $prometheus_service_name 
  assert_output "jaeger-query"

  prometheus_service_type=$($VKPR_KUBECTL get svc -n vkpr | grep jaeger-query | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $prometheus_service_type 
  assert_output "ClusterIP"
}

  # jaeger-collector
@test "check jaeger-collector service" {
  prometheus_service_name=$($VKPR_KUBECTL get svc -n vkpr | grep jaeger-collector | tr -s '[:space:]' ' ' | cut -d " " -f1)
  run echo $prometheus_service_name 
  assert_output "jaeger-collector"

  prometheus_service_type=$($VKPR_KUBECTL get svc -n vkpr | grep jaeger-collector | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $prometheus_service_type 
  assert_output "ClusterIP"
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

# prometheus-stack

@test "check prometheus-stack integration" {

  run $VKPR_YQ -i ".jaeger.metrics = true" $PWD/vkpr.yaml
  assert_success

  rit vkpr prometheus-stack install --default && \
  rit vkpr jaeger install --default

  prometheus_service_monitor_name=$($VKPR_KUBECTL get servicemonitor -n vkpr | grep jaeger-query | tr -s '[:space:]' ' ' | cut -d " " -f2)
  run echo $prometheus_service_monitor_name 
  assert_output "jaeger-query"

}

# validating jaeger metrics: true
@test "curl to prometheus API endpoint to jaeger_rpc_http_requests_total metric" {
 
  RESPONSE=$(curl -i prometheus.localhost:8000/api/v1/query?query=jaeger_rpc_http_requests_total | head -n1 | awk -F' ' '{print $2}')

  run echo $RESPONSE
  assert_output "200"
  assert_success

  RESPONSE=$(curl prometheus.localhost:8000/api/v1/query?query=jaeger_rpc_http_requests_total jq .status)

  run echo $RESPONSE
  assert_output "\"success\""
  assert_success
}

@test "check jaeger dashboard grafana status" {

  LOGIN_GRAFANA=$($VKPR_KUBECTL get secret --namespace vkpr prometheus-stack-grafana -o=jsonpath="{.data.admin-user}" | base64 -d)
  PWD_GRAFANA=$($VKPR_KUBECTL get secret --namespace vkpr prometheus-stack-grafana -o=jsonpath="{.data.admin-password}" | base64 -d)

  RESPONSE=$(curl http://$LOGIN_GRAFANA:$PWD_GRAFANA@grafana.localhost:8000/api/dashboards/tags | jq '.[] | select(.term == "vkpr-jaeger")')

  run echo $RESPONSE
  assert_output '{ "term": "vkpr-jaeger", "count": 1 }'
  assert_success 
}