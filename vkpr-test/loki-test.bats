VKPR_HOME=~/.vkpr
setup_file() {
    load 'common-setup'
    _common_setup
    if [ "$VKPR_TEST_SKIP_SETUP" == "true" ]; then
        echo "setup: skipping setup due to VKPR_TEST_SKIP_SETUP=true" >&3
    else
        echo "setup: installing loki...." >&3
        rit vkpr loki install
        $VKPR_KUBECTL wait --for=condition=ready --timeout=1m pod --all
        sleep 2
    fi
}

setup() {
    load $VKPR_HOME/bats/bats-support/load.bash
    load $VKPR_HOME/bats/bats-assert/load.bash
}

@test "curl to Loki must return ready" {
    run echo "$($VKPR_KUBECTL run --wait --timeout 1m curl-test --image=radial/busyboxplus:curl -i --rm --restart=Never --command -- curl -s  -H "Content-Type: application/json" http://vkpr-loki-stack:3100/ready)"
    actual="${lines[0]}"
    trim "$actual"
    actual="$TRIMMED"
    expected="ready"
    assert_equal "$actual" "$expected"
    
}

trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   
    TRIMMED="$var"
}