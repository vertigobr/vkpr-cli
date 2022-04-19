#!/usr/bin/env bash

source $(pwd)/lib/functions/log.sh
source $(pwd)/lib/functions/var.sh
source $(pwd)/lib/functions/helper.sh
source $(pwd)/lib/functions/validate.sh
source $(pwd)/lib/functions/versions.sh

_common_setup() {
  if [ "$VKPR_TEST_SKIP_SETUP" == "true" ]; then
    echo "common_setup: skipping common-setup due to VKPR_TEST_SKIP_SETUP=true" >&3
  else
    if [ "$($VKPR_K3D cluster list --no-headers | grep 'vkpr-local' | awk '{print $1}')" == "vkpr-local" ]; then
      echo "common_setup: vkpr cluster already created, skipping...." >&3
    else
      echo "common_setup: running vkpr cluster...." >&3
      rit vkpr infra start $1 --default
    fi
  fi
}

_common_teardown() {
  if [ "$VKPR_TEST_SKIP_TEARDOWN" == "true" ]; then
    echo "common_teardown: skipping common-teardown due to VKPR_TEST_SKIP_TEARDOWN=true" >&3
  elif [ "$VKPR_TEST_SKIP_COMMON_TEARDOWN" == "true" ]; then
    echo "common_teardown: skipping common-teardown due to VKPR_TEST_SKIP_COMMON_TEARDOWN=true" >&3
  else
    echo "common_teardown: killing vkpr cluster...." >&3
    rit vkpr infra down
  fi
}

