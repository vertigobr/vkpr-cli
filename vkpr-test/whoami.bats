
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
        echo "setup: installing whoami...." >&3
        rit vkpr whoami install --default
        $VKPR_KUBECTL wait --for=condition=ready --timeout=1m pod --all
        sleep 20
    fi
}

setup() {
    load $VKPR_HOME/bats/bats-support/load.bash
    load $VKPR_HOME/bats/bats-assert/load.bash
}

@test "Curl to Whoami and must return Hostname" {
    run curlWhoami
    actual="${lines[3]}"
    expected=$(podName)
    assert_equal "$actual" "$expected"
}

teardown_file() {
    if [ "$VKPR_TEST_SKIP_TEARDOWN" == "true" ]; then
        echo "teardown: skipping teardown due to VKPR_TEST_SKIP_TEARDOWN=true" >&3
    else
        echo "teardown: uninstalling ingress...." >&3
        rit vkpr ingress remove
        rit vkpr infra down
    fi
}

podName(){
  local pod=$($VKPR_KUBECTL get po -o name | grep whoami | cut -d "/" -f 2)
  echo "Hostname: ${pod}"
}

curlWhoami(){
  curl -k -H "Host: whoami.localhost" https://127.0.0.1:8001 | sed 's/<\/*[^>]*>//g'
  sleep 5
}