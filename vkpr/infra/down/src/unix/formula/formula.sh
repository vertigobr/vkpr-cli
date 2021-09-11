#!/bin/sh

runFormula() {
  echo "VKPR local infra stop routine"
  echo "=============================="
  stopCluster
}

stopCluster() {
  # local registry
  if $($VKPR_K3D cluster list | grep -q "vkpr-local"); then
    $VKPR_K3D cluster delete vkpr-local
  else
    echoColor "red" "Cluster vkpr-local not running, skipping."
  fi
}
