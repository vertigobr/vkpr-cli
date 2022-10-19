#!/usr/bin/env bash

source $PWD/lib/log.sh
source $PWD/lib/var.sh
source $PWD/lib/versions.sh

export LOG_DEBUG=true \
  LOG_TRACE=true \
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )" \
  PATH="$DIR:$PATH" \
  DETIK_CLIENT_NAME="kubectl"

_common_setup() {
  echo "***************************
        CAUTION!!!
YOUR \$PWD/vkpr.yaml WILL BE OVERRIDED IN THE TEST
SAVE THE FILE WITH ANOTHER NAME
***************************" >&3

  if [ "$VKPR_TEST_SKIP_SETUP_ACTIONS" == "true" ]; then
    echo "common_setup: skipping common_setup due to VKPR_TEST_SKIP_SETUP_ACTIONS=true" >&3
    return
  fi

  if [ "$($VKPR_K3D cluster list --no-headers | grep 'vkpr-local' | awk '{print $1}')" == "vkpr-local" ]; then
    echo "common_setup: vkpr cluster already created, skipping..." >&3
  else
    echo "common_setup: running vkpr cluster..." >&3
    rit vkpr infra start --nodeports=$1 --enable_volume=$2 --worker_nodes=$3
  fi
}

_common_teardown() {
  if [ "$VKPR_TEST_SKIP_SETUP_ACTIONS" == "true" ]; then
    echo "common_setup: skipping common_setup due to VKPR_TEST_SKIP_SETUP_ACTIONS=true" >&3
    return
  fi
  
  echo "common_teardown: killing vkpr cluster...." >&3
  rit vkpr infra down
}