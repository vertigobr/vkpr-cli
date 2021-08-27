#!/usr/bin/env bash

_common_setup() {
    if [ "$VKPR_TEST_SKIP_SETUP" == "true" ]; then
        echo "common_setup: skipping common-setup due to VKPR_TEST_SKIP_SETUP=true" >&3
    else
        if [ "$(k3d cluster list --no-headers | grep 'vkpr-local' | awk '{print $1}')" == "vkpr-local" ]; then
            echo "common_setup: vkpr cluster already created, skipping...." >&3
        else
            echo "common_setup: running vkpr cluster...." >&3
            rit vkpr infra up
        fi
    fi
}
