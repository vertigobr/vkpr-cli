VKPR_HOME=~/.vkpr

setup_file() {
    load 'common-setup'
    _common_setup
    if [ "$VKPR_TEST_SKIP_SETUP" == "true" ]; then
        echo "setup: skipping setup due to VKPR_TEST_SKIP_SETUP=true" >&3
    else
        echo "setup: installing loki...." >&3
        rit vkpr loki install
        sleep 2
    fi
}

setup() {
    load $VKPR_HOME/bats/bats-support/load.bash
    load $VKPR_HOME/bats/bats-assert/load.bash
}

@test "curl to Loki must return ready" {
    run echo "$($VKPR_HOME/bin/kubectl run --namespace vkpr --wait --rm -it --restart=Never --image=curlimages/curl curl --command -- curl -sH "Content-Type: application/json" http://loki-stack:3100/ready)"
    actual="${lines[0]}"
    trim "$actual"
    actual="$TRIMMED"
    expected="ready"
    assert_equal "$actual" "$expected"
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

trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   
    TRIMMED="$var"
}