VKPR_HOME=~/.vkpr

setup_file() {
    load 'common-setup'
    _common_setup
    if [ "$VKPR_TEST_SKIP_SETUP" == "true" ]; then
        echo "setup: skipping setup due to VKPR_TEST_SKIP_SETUP=true" >&3
    else
        echo "setup: installing cert-manager...." >&3
        rit vkpr cert-manager install --email test@test.com
        kubectl wait --for=condition=ready --timeout=1m pod --all
        sleep 2

        echo "setup: installing whoami to create a certificate...." >&3
        rit vkpr whoami install --domain whoami.vkpr-dev.vertigo.com.br --secure true
        kubectl wait --for=condition=ready --timeout=1m pod --all
        sleep 2
    fi
}

setup() {
    load $VKPR_HOME/bats/bats-support/load.bash
    load $VKPR_HOME/bats/bats-assert/load.bash
}

@test "curl to https://whoami.vkpr-dev.vertigo.com.br:8001 must return a letsencrypt certificate" {
    #command that tests whether ingress is running
    run "$(curl -vik --resolve whoami.vkpr-dev.vertigo.com.br:8001:127.0.0.1 https://whoami.vkpr-dev.vertigo.com.br:8001)"
    actual="${lines[1]}"
    trim "$actual"
    actual="$TRIMMED"
    expected="<>"
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
