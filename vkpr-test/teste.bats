
VKPR_HOME=~/.vkpr

setup_file() {
    load 'common-setup'
    _common_setup
}

setup() {
    load $VKPR_HOME/bats/bats-support/load.bash
    load $VKPR_HOME/bats/bats-assert/load.bash
}

@test "teste 01" {
    echo "Welcome to our project!"
    assert_equal 'oioi' 'oioi'
}

# teardown() {
# }

teardown_file() {
    echo "teardown...."
}

