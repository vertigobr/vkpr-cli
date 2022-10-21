#!/usr/bin/env bash

export VKPR_HOME=~/.vkpr \
  VKPR_CONFIG=~/.vkpr/config \
  VKPR_FILE=$CURRENT_PWD/vkpr.yaml \
  VKPR_CREDENTIAL=~/.rit/credentials/default

export VKPR_BATS=$VKPR_HOME/bats/bin/bats \
  VKPR_K3D=$VKPR_HOME/bin/k3d \
  VKPR_ARKADE=$VKPR_HOME/bin/arkade \
  VKPR_OKTETO=$VKPR_HOME/bin/okteto \
  VKPR_KUBECTL=$VKPR_HOME/bin/kubectl \
  VKPR_HELM=$VKPR_HOME/bin/helm \
  VKPR_JQ=$VKPR_HOME/bin/jq \
  VKPR_YQ=$VKPR_HOME/bin/yq \
  VKPR_DECK=$VKPR_HOME/bin/deck \
  VKPR_AWS=$VKPR_HOME/bin/aws
