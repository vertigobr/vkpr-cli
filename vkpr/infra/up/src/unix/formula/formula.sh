#!/bin/sh

runFormula() {
  echo "VKPR local infra start routine"
  echo "=============================="
  echoColor "yellow" "Ports used:"
  echo "Kubernetes API: "
  echo "Ingress controller (load balancer): "
  echo "Local registry: 5000"
  echo "Docker Hub registry mirror (cache): 5001"
  echoColor "yellow" "Volumes used:"
  echo "Two local unamed docker volumes"

  VKPR_CONFIG_REGISTRY=$VKPR_HOME/config/registry.yaml

  # TODO: test dependencies

  # VKPR home is "~/.vkpr"
  # starts local registry and mirror
  configRegistry
  startRegistry
  # starts kubernetes using registries
  startCluster
}

configRegistry() {
  #HOST_IP="172.17.0.1" # linux native
  HOST_IP="host.k3d.internal"
  cat > $VKPR_CONFIG_REGISTRY << EOF
mirrors:
  "docker.io":
    endpoint:
      - "http://$HOST_IP:5001"
EOF
}

startCluster() {
  # local registry
  if ! $($VKPR_K3D cluster list | grep -q "vkpr-local"); then
    $VKPR_K3D cluster create vkpr-local \
      -p "8000:80@loadbalancer" \
      -p "8001:443@loadbalancer" \
      --k3s-server-arg '--no-deploy=traefik' \
      --registry-use k3d-registry.localhost \
      --registry-config $VKPR_CONFIG_REGISTRY
  else
    echoColor "yellow" "Cluster vkpr-local already started, skipping."
  fi
  # use cluster
  $VKPR_KUBECTL config use-context k3d-vkpr-local
  $VKPR_KUBECTL cluster-info
}

startRegistry() {
  # local registry
  if ! $($VKPR_K3D registry list | grep -q "k3d-registry\.localhost"); then
    $VKPR_K3D registry create registry.localhost -p 5000
  else
    echoColor "yellow" "Registry already started, skipping."
  fi
  # docker hub mirror
  if ! $($VKPR_K3D registry list | grep -q "k3d-mirror\.localhost"); then
    $VKPR_K3D registry create mirror.localhost -i vertigo/registry-mirror -p 5001
  else
    echoColor "yellow" "Mirror already started, skipping."
  fi
}
