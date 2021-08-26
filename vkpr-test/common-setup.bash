#!/usr/bin/env bash

_common_setup() {
    if [ "$VKPR_TEST_SKIP_SETUP" == "true" ]; then
        echo "skipping common-setup due to VKPR_TEST_SKIP_SETUP=true"
    else
        echo "running cluster and installing ingress...."
        rit vkpr infra up
    fi
}
