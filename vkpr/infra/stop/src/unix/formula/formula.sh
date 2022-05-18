#!/bin/bash

runFormula() {
  echo "=============================="
  info "VKPR Local Infra Stop Routine"
  echo "=============================="
  stopCluster
}

stopCluster() {
  if ${VKPR_K3D} cluster list | grep -q "vkpr-local"; then
    ${VKPR_K3D} cluster delete vkpr-local
  else
    error "Cluster vkpr-local not running..."
  fi
  if [[ $DELETE_REGISTRY == "true" ]]; then
    docker rm -f k3d-mirror.localhost k3d-registry.localhost > /dev/null
  fi
}
