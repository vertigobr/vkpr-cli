#!/usr/bin/env bats

# ~/.vkpr/bats/bin/bats vkpr-test/postgres/postgres.bats

export DETIK_CLIENT_NAMESPACE="vkpr"
load '../.bats/common.bats'

setup() {
  load "$VKPR_HOME/bats/bats-support/load"
  load "$VKPR_HOME/bats/bats-assert/load"
  load "$VKPR_HOME/bats/bats-detik/load"
  load "$VKPR_HOME/bats/bats-file/load"  
  export FIRST_REPO="$(rit list repo | tail -n +2 | head -n3 | awk -F' ' '{print $2}' | tr '\n' ' ' | column -t | awk -F' ' '{print $1}')"
  source ~/.rit/repos/$FIRST_REPO/lib/functions/kubernetes-operators.sh
}

setup_file() {
  touch $PWD/vkpr.yaml

  [ "$VKPR_TEST_SKIP_ALL" == "true" ] && echo "common_setup: skipping common_setup due to VKPR_TEST_SKIP_ALL=true" >&3 && return
  _common_setup "1" "false" "1"

  if [ "$VKPR_TEST_SKIP_DEPLOY_ACTIONS" == "true" ]; then
    echo "common_setup: skipping common_setup due to VKPR_TEST_SKIP_DEPLOY_ACTIONS=true" >&3
    return
  else
    echo "setup: installing postgres..." >&3
    rit vkpr postgresql install --default
  fi
}

teardown_file() {
  if [ "$VKPR_TEST_SKIP_ALL" == "true" ]; then
    echo "common_setup: skipping common_setup due to VKPR_TEST_SKIP_ALL=true" >&3
    return
  fi

  if [ "$VKPR_TEST_SKIP_DEPLOY_ACTIONS" == "true" ]; then
    echo "common_setup: skipping common_setup due to VKPR_TEST_SKIP_DEPLOY_ACTIONS=true" >&3
  else
    echo "Uninstall postgres" >&3
    rit vkpr postgresql remove
  fi

  _common_teardown
}

teardown() {
  $VKPR_YQ -i "del(.global) | del(.postgresql)" $PWD/vkpr.yaml
}

@test "use function checkExistingDatabase to check the database" {
  POSTGRES_PASSWORD=$($VKPR_KUBECTL get secret -n vkpr postgres-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)
  sleep 2
  expected=$($VKPR_KUBECTL run pgsql-client --rm --tty -i --restart='Never' \
                --namespace vkpr --image docker.io/bitnami/postgresql \
                --env="PGUSER=postgres" --env="PGPASSWORD=vkpr123" --env="PGHOST=postgres-postgresql.vkpr" --env="PGPORT=5432" --env="PGDATABASE=postgres" \
                --command -- psql -lsqt | cut -d \| -f 1 | grep "postgres" | sed -e 's/^[ \t]*//')

  assert_equal "postgres" "${expected}"
  assert_success
}

@test "use function createDatabase to create a new database" {
  POSTGRES_PASSWORD=$($VKPR_KUBECTL get secret -n vkpr postgres-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)
  sleep 2
  expected=$(createDatabase "postgres" "postgres-postgresql.vkpr" "$POSTGRES_PASSWORD" "test" "vkpr")
  
  run echo ${expected}

  assert_line --partial "CREATE DATABASE"
  assert_success
}

@test "Use another chart to use postgresql in HA mode" {
  rit vkpr postgresql install --HA="true" --default
  sleep 10

  expected=$($VKPR_HELM ls -A -o=json | $VKPR_JQ -r '.[] | select(.name | contains("postgresql")) | .chart')
  run echo $expected

  assert_line --regexp --index 0 "^postgresql-[0-9]+\.[0-9]+\.[0-9]$"
  assert_success
}

@test "Use vkpr.yaml to change values in postgresql with globals" {
  useVKPRfile changeYAMLfile ".global.namespace = \"vtg\" |
    .postgresql.namespace = \"vkpr\"
  "
  sleep 10

  run $VKPR_HELM ls -A -o=json | $VKPR_JQ -r '.[] | select(.name | contains("postgresql"))'

  refute_line --partial "\"namespace\":\"vtg\""
  assert_success
}

@test "Use vkpr.yaml to merge values in postgresql with helmArgs" {
  rit vkpr postgresql remove --default # Fails if dont remove the postgresql

  testValue="postgres-test"
  useVKPRfile changeYAMLfile ".postgresql.helmArgs.nameOverride = \"${testValue}\""
  sleep 10

  run $VKPR_HELM get values postgresql -n vkpr
  
  assert_line --partial "nameOverride: postgres-test"
  assert_success
}

@test "use formula createdb to create a new database" {
  POSTGRES_PASSWORD=$($VKPR_KUBECTL get secret -n vkpr postgresql-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)
  
  run rit vkpr postgresql createdb --dbname="test2" --dbuser="test" --dbpassword="test"

  assert_line --partial "CREATE DATABASE"
  assert_success
}

teardown_file() {
  if [ "$VKPR_TEST_SKIP_TEARDOWN" == "true" ]; then
    echo "teardown: skipping teardown due to VKPR_TEST_SKIP_TEARDOWN=true" >&3
  else
    echo "teardown: uninstalling postgres...." >&3
    rit vkpr postgresql remove --default
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
  $VKPR_YQ eval -i "del(.postgresql)" vkpr.yaml
  $VKPR_YQ eval "${1}" vkpr.yaml > vkpr.yaml
  rit vkpr postgresql install $2 --default
}
