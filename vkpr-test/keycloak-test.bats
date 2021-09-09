
VKPR_HOME=~/.vkpr

setup_file() {
    load 'common-setup'
    _common_setup
    if [ "$VKPR_TEST_SKIP_SETUP" == "true" ]; then
        echo "setup: skipping setup due to VKPR_TEST_SKIP_SETUP=true" >&3
    else
        echo "setup: installing ingress...." >&3
        rit vkpr ingress install
        kubectl wait --for=condition=ready --timeout=1m pod --all
        echo "setup: installing keycloak...." >&3
        rit vkpr keycloak install --default
        kubectl wait --for=condition=ready --timeout=1m pod --all
        sleep 2
    fi
}

setup() {
    load $VKPR_HOME/bats/bats-support/load.bash
    load $VKPR_HOME/bats/bats-assert/load.bash
}

@test "Check if keycloak is up" {
    run curlKeycloak
    actual="${lines[3]}"
    trim "$actual"
    actual="$TRIMMED"
    expected='"realm":"master"'
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
  content=$(curl -H "Host: keycloak.localhost" http://127.0.0.1:8000/auth/realms/master)
  echo ${content:1:16}
}

trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   
    TRIMMED="$var"
}