# TESTS

Automated BATS tests for VKPR formulas.

## BATS in VKPR

Tests written using [BATS](https://bats-core.readthedocs.io/en/stable/index.html).

BATS itself is installed by `vkpr init` formula.

A few points:

- BATS supports `setup` and `teardown` operations defined in each `.bats` file (invoked before and after **each test** in that file).
- BATS also supports `setup_file` and `teardown_file` operations defined in each `.bats` file (invoked **once** before and after each file).
- VKPR tests also rely on a shared `common_setup.bash` that is invoked by all `setup_file` operations (by convention), to implement "smart" warm-ups and caches for all tests

A typical `bats` file is like this:

```sh
VKPR_HOME=~/.vkpr

setup_file() {
    load 'common-setup'
    _common_setup
    # here goes 'once per file' setup code
}

setup() {
    load $VKPR_HOME/bats/bats-support/load.bash
    load $VKPR_HOME/bats/bats-assert/load.bash
    # here goes 'once per test' setup code
}

# here goes all tests
@test "this is a test" {
    # here is some test code
}
```

## Running individual tests

You can run individual tests quickly (for a TDD approach) by disabling actions in infra content and specifying the test file:

```
VKPR_TEST_SKIP_SETUP_ACTIONS=true ~/.vkpr/bats/bin/bats vkpr-test/whoami/main.bats
```

or to disable only the deploy of applications:

```
VKPR_TEST_SKIP_DEPLOY_ACTIONS=true ~/.vkpr/bats/bin/bats vkpr-test/whoami/main.bats
```

and skipping all steps and only run the code:

```
VKPR_TEST_SKIP_ALL=true ~/.vkpr/bats/bin/bats vkpr-test/whoami/main.bats
```

## Running all tests

You can run all tests by running BATS against the tests folder:

```
~/.vkpr/bats/bin/bats vkpr-tests
```
