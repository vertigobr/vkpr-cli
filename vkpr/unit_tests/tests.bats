#!/usr/bin/env bats

load '/home/humberto/Documentos/vertigo/vkpr-cli/bats/libexec/test/test_helper/bats-support/load.bash'
load '/home/humberto/Documentos/vertigo/vkpr-cli/bats/libexec/bats-assert/load.bash'

@test "addition using bc" {
  result="$(echo 2+2 | bc)"
  [ "$result" -eq 4 ]
}

@test "addition using dc" {
    run "$(curl localhost:8000)"
    actual="${lines[1]}"
    trim "$actual"
    actual="$TRIMMED"
    expected="<head><title>404 Not Found</title></head>"
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
