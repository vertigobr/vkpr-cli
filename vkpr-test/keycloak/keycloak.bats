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
    echo "setup: installing postgres..." >&3
    rit vkpr postgres install --default
    echo "setup: installing keycloak..." >&3
    rit vkpr keycloak install --default
  fi
}

setup() {
  load $VKPR_HOME/bats/bats-support/load.bash
  load $VKPR_HOME/bats/bats-assert/load.bash
}

@test "import mock realm with formula" {
  rit vkpr keycloak import realm --realm_path="$PWD/realm.json" --keycloak_username="admin" --keycloak_password="vkpr123"
  sleep 10

  assert_success
}

@test "Show the name from userinfo with OpenID endpoint" {
  run curlKeycloakUserinfo
  sleep 10

  assert_line --partial "Sample Admin"
  assert_success
}

curlKeycloakUserinfo(){
  TOKEN_VALUE=$(wget -qO- http://keycloak.localhost:8000/auth/realms/grafana/protocol/openid-connect/token/ \
    --header="Content-Type: application/x-www-form-urlencoded" \
    --post-data="grant_type=password&username=sample-admin&password=password&client_secret=3162d962-c3d1-498e-8cb3-a1ae0005c4d9&client_id=grafana&scope=openid" | $VKPR_HOME/bin/yq e '.access_token' -
  )
  content=$(wget -qO- http://keycloak.localhost:8000/auth/realms/grafana/protocol/openid-connect/userinfo \
    --header="Authorization: Bearer ${TOKEN_VALUE}" | $VKPR_HOME/bin/yq e '.name' -
  )
  echo ${content}
}

@test "export mock realm with formula" {
  rit vkpr keycloak export realm --realm_name="grafana" --keycloak_username="admin" --keycloak_password="vkpr123"
  run $VKPR_HOME/bin/yq e .id $PWD/grafana-realm.json
  sleep 10

  assert [ -e $PWD/grafana-realm.json ]
  assert_line --partial "grafana"
  rm grafana-realm.json
  assert_success
}

@test "export mock users with formula" {
  rit vkpr keycloak export users --realm_name="grafana" --keycloak_username="admin" --keycloak_password="vkpr123"
  run $VKPR_HOME/bin/yq e ".users[0].username" $PWD/grafana-users.json
  sleep 10

  assert [ -e $PWD/grafana-users.json ]
  assert_line --partial "sample-admin"
  rm grafana-users.json
  assert_success
}

@test "export mock clients with formula" {
  rit vkpr keycloak export clients --realm_name="grafana" --keycloak_username="admin" --keycloak_password="vkpr123"
  run $VKPR_HOME/bin/yq e ".clients[0].id" $PWD/grafana-clientsid.json
  sleep 10

  assert [ -e $PWD/grafana-clientsid.json ]
  assert_line --partial "ae675ff1-eb36-4751-816b-d34b41300669"
  rm grafana-clientsid.json
  assert_success
}

@test "Use vkpr.yaml to merge values in keycloak with helmArgs" {
  testValue="keycloak-test"
  useVKPRfile changeYAMLfile ".keycloak.helmArgs.fullnameOverride = \"${testValue}\" |
    .keycloak.helmArgs.ingress.path = \"/test\"
  "
  sleep 10

  run $VKPR_HELM get values keycloak -n vkpr
  assert_line --partial "fullnameOverride: keycloak-test"
  assert_success
}

@test "Use vkpr.yaml to change values in keycloak with globals" {
  useVKPRfile changeYAMLfile ".global.namespace = \"vtg\" |
    .keycloak.namespace = \"vkpr\"
  "
  sleep 10

  run $VKPR_HELM ls -A -o=json | $VKPR_JQ -r '.[] | select(.name | contains("keycloak"))'

  refute_line --partial "\"namespace\":\"vtg\""
  assert_success
}

teardown_file() {
  if [ "$VKPR_TEST_SKIP_TEARDOWN" == "true" ]; then
    echo "teardown: skipping uninstall due to VKPR_TEST_SKIP_TEARDOWN=true" >&3
  else
    echo "teardown: uninstalling keycloak..." >&3
    rit vkpr keycloak remove
    echo "teardown: uninstalling postgresql..." >&3
    rit vkpr postgres remove --delete_pvc="true"
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
  $VKPR_YQ eval -i "del(.keycloak)" vkpr.yaml
  $VKPR_YQ eval "${1}" vkpr.yaml > vkpr.yaml
  rit vkpr keycloak install $2 --default
}
