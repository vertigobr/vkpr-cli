setup() {
  load $VKPR_HOME/bats/bats-support/load.bash
  load $VKPR_HOME/bats/bats-assert/load.bash
  load $(pwd)/lib/functions/helper.sh
}

setup_file() {
  load '../.bats/common.bats.bash'
  _common_setup

  if [ "$VKPR_TEST_SKIP_PROVISIONING" == "true" ]; then
    echo "setup: skipping provisionig due to VKPR_TEST_SKIP_PROVISIONING=true" >&3
  else
    echo "setup: installing postgres..." >&3
    rit vkpr postgres install --default
  fi
}

@test "use function checkExistingDatabase to check the database" {
  POSTGRES_PASSWORD=$($VKPR_KUBECTL get secret -n vkpr postgres-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)
  expected=$(checkExistingDatabase "postgres" "$POSTGRES_PASSWORD" "postgres" "vkpr" | xargs)

  assert_equal "postgres" "${expected}"
  assert_success
}

@test "use function createDatabase to create a new database" {
  POSTGRES_PASSWORD=$($VKPR_KUBECTL get secret -n vkpr postgres-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)
  expected=$(createDatabase "postgres" "$POSTGRES_PASSWORD" "test" "vkpr")
  
  run echo ${expected}

  assert_line --partial "CREATE DATABASE"
  assert_success
}

@test "Use another chart to use postgresql in HA mode" {
  rit vkpr postgres install --HA="true" --default
  sleep 10

  expected=$($VKPR_HELM ls -A -o=json | $VKPR_JQ -r '.[] | select(.name | contains("postgresql")) | .chart')
  run echo $expected

  assert_line --regexp --index 0 "^postgresql-ha-[0-9]+\.[0-9]+\.[0-9]$"
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
  rit vkpr postgres remove --default # Fails if dont remove the postgresql

  testValue="postgres-test"
  useVKPRfile changeYAMLfile ".postgresql.helmArgs.nameOverride = \"${testValue}\""
  sleep 10

  run $VKPR_HELM get values postgresql -n vkpr
  
  assert_line --partial "nameOverride: postgres-test"
  assert_success
}

@test "use formula createdb to create a new database" {
  POSTGRES_PASSWORD=$($VKPR_KUBECTL get secret -n vkpr postgres-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)
  
  run rit vkpr postgres createdb --dbname="test2" --dbuser="test" --dbpassword="test"

  assert_line --partial "CREATE DATABASE"
  assert_success
}

teardown_file() {
  if [ "$VKPR_TEST_SKIP_TEARDOWN" == "true" ]; then
    echo "teardown: skipping teardown due to VKPR_TEST_SKIP_TEARDOWN=true" >&3
  else
    echo "teardown: uninstalling postgres...." >&3
    rit vkpr postgres remove --default
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
  rit vkpr postgres install $2 --default
}
