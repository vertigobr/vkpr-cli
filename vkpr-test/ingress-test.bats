
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
        sleep 2
    fi
}

setup() {
    load $VKPR_HOME/bats/bats-support/load.bash
    load $VKPR_HOME/bats/bats-assert/load.bash
}

@test "curl to localhost:8000 must return 404" {
    #command that tests whether ingress is running
    run "$(curl localhost:8000)"
    actual="${lines[1]}"
    trim "$actual"
    actual="$TRIMMED"
    expected="<head><title>404 Not Found</title></head>"
    assert_equal "$actual" "$expected"
}

@test "curl to https://localhost:8001 must return 404" {
    #command that tests whether ingress is running
    run "$(curl -k https://localhost:8001)"
    actual="${lines[1]}"
    trim "$actual"
    actual="$TRIMMED"
    expected="<head><title>404 Not Found</title></head>"
    assert_equal "$actual" "$expected"
}

# teardown() {
# }

teardown_file() {
    if [ "$VKPR_TEST_SKIP_TEARDOWN" == "true" ]; then
        echo "teardown: skipping teardown due to VKPR_TEST_SKIP_TEARDOWN=true" >&3
    else
        echo "teardown: uninstalling ingress...." >&3
        rit vkpr ingress remove
        rit vkpr infra down --default
    fi
}

trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   
    TRIMMED="$var"
}
