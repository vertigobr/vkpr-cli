VKPR_HOME=~/.vkpr
load $VKPR_HOME/bats/bats-support/load.bash
load $VKPR_HOME/bats/bats-assert/load.bash

setup_file() {
    if [ "$VKPR_TEST_SKIP_SETUP" == "true" ]; then
        echo "skipping setup due to VKPR_TEST_SKIP_SETUP=true"
    else
        echo "running cluster and installing ingress...."
        rit vkpr infra up
        rit vkpr ingress install
        kubectl wait --for=condition=ready --timeout=30s pod --all
        sleep 2
    fi
}

# setup() {
# }

@test "curl to localhost:8000 must return 404" {
    #command that tests whether ingress is running
    run "$(curl localhost:8000)"
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
        echo "skipping teardown due to VKPR_TEST_SKIP_TEARDOWN=true"
    else
        echo "uninstalling ingress...."
        rit vkpr ingress remove
        rit vkpr infra down
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
