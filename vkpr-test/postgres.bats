
VKPR_HOME=~/.vkpr

setup_file() {
    load 'common-setup'
    _common_setup
    if [ "$VKPR_TEST_SKIP_SETUP" == "true" ]; then
        echo "setup: skipping setup due to VKPR_TEST_SKIP_SETUP=true" >&3
    else
        echo "setup: installing postgres...." >&3
        rit vkpr postgres install
        kubectl wait --for=condition=ready --timeout=1m pod --all
        sleep 2
    fi
}

setup() {
    load $VKPR_HOME/bats/bats-support/load.bash
    load $VKPR_HOME/bats/bats-assert/load.bash
}

@test "Ping in DB and must show if is accepting connections" {
    run ping_db
    actual="${lines[0]}"
    expected="postgres-postgresql:5432 - accepting connections"
    assert_equal "$actual" "$expected"
}

teardown_file() {
    if [ "$VKPR_TEST_SKIP_TEARDOWN" == "true" ]; then
        echo "teardown: skipping teardown due to VKPR_TEST_SKIP_TEARDOWN=true" >&3
    else
        echo "teardown: uninstalling postgres...." >&3
        rit vkpr postgres remove
        rit vkpr infra down --default
    fi
}

ping_db(){
    $VKPR_HOME/bin/kubectl run test-db --rm -it --restart='Never' --image docker.io/bitnami/postgresql:11.13.0-debian-10-r12 --env="PGUSER=postgres" --env="PGPASSWORD=123" --env="PGHOST=postgres-postgresql" --env="PGPORT=5432" --command -- pg_isready
}