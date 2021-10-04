
VKPR_HOME=~/.vkpr

setup_file() {
    load 'common-setup'
    _common_setup
    if [ "$VKPR_TEST_SKIP_SETUP" == "true" ]; then
        echo "setup: skipping setup due to VKPR_TEST_SKIP_SETUP=true" >&3
    else
        echo "setup: installing ingress..." >&3
        rit vkpr ingress install
        echo "setup: installing whoami..." >&3
        rit vkpr whoami install --default
        sleep 2
    fi
}

setup() {
    load $VKPR_HOME/bats/bats-support/load.bash
    load $VKPR_HOME/bats/bats-assert/load.bash
}

@test "cURL to Whoami with HTTP and must return Hostname" {
    run curlWhoamiHttp
    actual="${lines[3]}"
    expected=$(podName)
    assert_equal "$actual" "$expected"
}

@test "cURL to Whoami with HTTPS and must return Hostname" {
    rit vkpr whoami install --secure="true" --default
    run curlWhoamiHttps
    actual="${lines[3]}"
    expected=$(podName)
    assert_equal "$actual" "$expected"
}

teardown_file() {
    if [ "$VKPR_TEST_SKIP_TEARDOWN" == "true" ]; then
        echo "teardown: skipping teardown due to VKPR_TEST_SKIP_TEARDOWN=true" >&3
    else
        echo "teardown: uninstalling whoami..." >&3
        rit vkpr whoami remove
        echo "teardown: uninstalling ingress..." >&3
        rit vkpr ingress remove
        rit vkpr infra down --default
    fi
}

podName(){
  local pod=$($VKPR_HOME/bin/kubectl get po -o name -n vkpr | grep whoami | cut -d "/" -f 2)
  echo "Hostname: ${pod}"
}

curlWhoamiHttp(){
  curl -k -H "Host: whoami.localhost" http://127.0.0.1:8000 | sed 's/<\/*[^>]*>//g'
  sleep 2
}

curlWhoamiHttps(){
  curl -k -H "Host: whoami.localhost" https://127.0.0.1:8001 | sed 's/<\/*[^>]*>//g'
  sleep 2
}