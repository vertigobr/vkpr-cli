VKPR_HOME=~/.vkpr
load  $VKPR_HOME/test/bats-support/load.bash
load $VKPR_HOME/test/bats-assert/load.bash


setup() {
    echo "installing ingress...."
    rit vkpr ingress install
    kubectl wait --for=condition=ready --timeout=30s pod --all
    sleep 2
    
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

teardown() {
  echo "uninstalling ingress...."
  rit vkpr ingress remove
}

trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   
    TRIMMED="$var"
}
