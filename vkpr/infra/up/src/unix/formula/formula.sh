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

  # TODO: test dependencies

  # VKPR home is "~/.vkpr"
  VKPR_HOME=~/.vkpr
  # starts local registry and mirror
  configRegistry
  startRegistry
  # starts kubernetes using registries
  startCluster
}

configRegistry() {
  #HOST_IP="172.17.0.1" # linux native
  HOST_IP="host.k3d.internal"
  cat > $VKPR_HOME/config/registry.yaml << EOF
mirrors:
  "docker.io":
    endpoint:
      - "http://$HOST_IP:5001"
EOF
}

startCluster() {
  # local registry
  if ! $(k3d cluster list | grep -q "vkpr-local"); then
    k3d cluster create vkpr-local \
      -p "8000:80@loadbalancer" \
      --k3s-server-arg '--no-deploy=traefik' \
      --registry-use k3d-registry.localhost \
      --registry-config $VKPR_HOME/config/registry.yaml
  else
    echoColor "yellow" "Cluster vkpr-local already started, skipping."
  fi
  # use cluster
  $VKPR_HOME/bin/kubectl config use-context k3d-vkpr-local
  $VKPR_HOME/bin/kubectl cluster-info
}

startRegistry() {
  # local registry
  if ! $(k3d registry list | grep -q "k3d-mirror.localhost"); then
    k3d registry create registry.localhost -p 5000
  else
    echoColor "yellow" "Registry already started, skipping."
  fi
  # docker hub mirror
  if ! $(k3d registry list | grep -q "k3d-registry.localhost"); then
    k3d registry create mirror.localhost -i vertigo/registry-mirror -p 5001
  else
    echoColor "yellow" "Mirror already started, skipping."
  fi
}

echoColor() {
  case $1 in
    red)
      echo "$(printf '\033[31m')$2$(printf '\033[0m')"
      ;;
    green)
      echo "$(printf '\033[32m')$2$(printf '\033[0m')"
      ;;
    yellow)
      echo "$(printf '\033[33m')$2$(printf '\033[0m')"
      ;;
    blue)
      echo "$(printf '\033[34m')$2$(printf '\033[0m')"
      ;;
    cyan)
      echo "$(printf '\033[36m')$2$(printf '\033[0m')"
      ;;
    esac
}
