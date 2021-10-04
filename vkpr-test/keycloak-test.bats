
VKPR_HOME=~/.vkpr

setup_file() {
    load 'common-setup'
    _common_setup
    if [ "$VKPR_TEST_SKIP_SETUP" == "true" ]; then
        echo "setup: skipping setup due to VKPR_TEST_SKIP_SETUP=true" >&3
    else
        echo "setup: installing ingress...." >&3
        rit vkpr ingress install
        $VKPR_KUBECTL wait --for=condition=ready --timeout=1m pod --all
        echo "setup: installing keycloak...." >&3
        rit vkpr keycloak install --default
        $VKPR_KUBECTL wait --for=condition=ready --timeout=2m pod --all
        sleep 60
        sleep 2
    fi
}

setup() {
    load $VKPR_HOME/bats/bats-support/load.bash
    load $VKPR_HOME/bats/bats-assert/load.bash
}

@test "Check if keycloak is up" {
    run curlKeycloak
    expected='"realm":"master"'
    assert_equal "$output" "$expected"
}

@test "Generate Token to use in OpenID" {
    run curlKeycloakToken
    actual="${lines[3]}"
    trim "$actual"
    expected='"access_token"'
    assert_equal "$actual" "$expected"
}

@test "Show the name from userinfo with OpenID endpoint" {
    run curlKeycloakUserinfo
    actual="${lines[6]}"
    trim "$actual"
    expected='Sample Admin'
    assert_equal "$actual" "$expected"
}

teardown_file() {
    if [ "$VKPR_TEST_SKIP_TEARDOWN" == "true" ]; then
        echo "teardown: skipping teardown due to VKPR_TEST_SKIP_TEARDOWN=true" >&3
    else
        echo "teardown: uninstalling ingress...." >&3
        rit vkpr keycloak remove
        sleep 5
        rit vkpr ingress remove
        sleep 5
        rit vkpr infra down
        sleep 5
    fi
}

curlKeycloak(){
  content=$(curl -s -H "Host: vkpr-keycloak.localhost" http://127.0.0.1:8000/auth/realms/master)
  echo ${content:1:16}
}

curlKeycloakToken(){
    content=$(curl -X POST -H "Host: vkpr-keycloak.localhost" -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=password&username=sample-admin&password=password&client_secret=3162d962-c3d1-498e-8cb3-a1ae0005c4d9&client_id=grafana&scope=openid" http://127.0.0.1:8000/auth/realms/grafana/protocol/openid-connect/token/)
    echo ${content:1:14}
}

curlKeycloakUserinfo(){
    TOKEN_VALUE=$(curl -X POST -H "Host: vkpr-keycloak.localhost" -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=password&username=sample-admin&password=password&client_secret=3162d962-c3d1-498e-8cb3-a1ae0005c4d9&client_id=grafana&scope=openid" http://127.0.0.1:8000/auth/realms/grafana/protocol/openid-connect/token/ | $VKPR_JQ -r '.access_token')
    content=$(curl -X POST -H "Host: vkpr-keycloak.localhost" -H "Authorization: Bearer ${TOKEN_VALUE}" http://127.0.0.1:8000/auth/realms/grafana/protocol/openid-connect/userinfo | $VKPR_JQ -r '.name')
    echo ${content}
}

trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   
    TRIMMED="$var"
}