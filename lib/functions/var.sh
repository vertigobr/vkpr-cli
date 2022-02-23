#!/bin/bash

export VKPR_HOME=~/.vkpr \
  VKPR_GLOBAL=$CURRENT_PWD/vkpr.yaml \
  VKPR_CONFIG=$VKPR_HOME/config \
  VKPR_K8S_NAMESPACE="vkpr"

export VKPR_GLAB=$VKPR_HOME/bin/glab \
  VKPR_K3D=$VKPR_HOME/bin/k3d \
  VKPR_ARKADE=$VKPR_HOME/bin/arkade \
  VKPR_KUBECTL=$VKPR_HOME/bin/kubectl \
  VKPR_HELM=$VKPR_HOME/bin/helm \
  VKPR_JQ=$VKPR_HOME/bin/jq \
  VKPR_YQ=$VKPR_HOME/bin/yq
