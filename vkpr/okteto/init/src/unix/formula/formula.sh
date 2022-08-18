#!/usr/bin/env bash

runFormula() {
  $VKPR_OKTETO context use https://cloud.okteto.com
  $VKPR_OKTETO namespace
  $VKPR_OKTETO kubeconfig
}
