#!/bin/sh

runFormula() {
  local SERVERS=1
  local AGENTS=1

  checkGlobalConfig $HTTP_PORT "8000" "infra.http_port" "HTTP_PORT"
  checkGlobalConfig $HTTPS_PORT "8001" "infra.https_port" "HTTPS_PORT"
  checkGlobalConfig $ENABLE_TRAEFIK "false" "infra.traefik.enabled" "TRAEFIK"
  checkGlobalConfig $SERVERS "1" "infra.resources.servers" "K3D_SERVERS"
  checkGlobalConfig $AGENTS "1" "infra.resources.agents" "K3D_AGENTS"

  startInfos
  configRegistry
  startRegistry
  startCluster
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Local Infra Start Routine")"
  echoColor "bold" "$(echoColor "blue" "Enabled Traefik Ingress Controller:") ${VKPR_ENV_TRAEFIK}"
  echoColor "bold" "$(echoColor "blue" "Ports Used:") :${VKPR_ENV_HTTP_PORT}/http :${VKPR_ENV_HTTPS_PORT}/https"
  echoColor "bold" "$(echoColor "blue" "Kubernetes API:") :6443"
  echoColor "bold" "$(echoColor "blue" "Local Registry:") :5000"
  echoColor "bold" "$(echoColor "blue" "Docker Hub Registry Mirror (cache):") :5001"
  echoColor "bold" "$(echoColor "yellow" "Using two local unamed Docker Volumes")"
  echo "=============================="
}

configRegistry() {
  #local HOST_IP="172.17.0.1"  #Linux Native
  local HOST_IP="host.k3d.internal"
  cat > ${VKPR_CONFIG}/registry.yaml << EOF
mirrors:
  "docker.io":
    endpoint:
      - "http://$HOST_IP:5001"
EOF
}

# Create the local registry and Docker Hub Mirror
startRegistry() {
  if ! $(${VKPR_K3D} registry list | grep -q "k3d-registry\.localhost"); then
    ${VKPR_K3D} registry create registry.localhost -p 5000
  else
    echoColor "yellow" "Registry already started, skipping..."
  fi
  if ! $(${VKPR_K3D} registry list | grep -q "k3d-mirror\.localhost"); then
    ${VKPR_K3D} registry create mirror.localhost -i vertigo/registry-mirror -p 5001
  else
    echoColor "yellow" "Mirror already started, skipping..."
  fi
}

# Starts K8S using Registries
startCluster() {
  local TRAEFIK_FLAG=""
  if [ "${ENABLE_TRAEFIK}" == "false" ]; then
    TRAEFIK_FLAG="--no-deploy=traefik"
  fi
  if ! $(${VKPR_K3D} cluster list | grep -q "vkpr-local"); then
    ${VKPR_K3D} cluster create vkpr-local \
      -s ${VKPR_ENV_K3D_SERVERS} -a ${VKPR_ENV_K3D_AGENTS} \
      -p "${VKPR_ENV_HTTP_PORT}:80@loadbalancer" \
      -p "${VKPR_ENV_HTTPS_PORT}:443@loadbalancer" \
      --k3s-server-arg "${TRAEFIK_FLAG}" \
      --registry-use k3d-registry.localhost \
      --registry-config ${VKPR_CONFIG}/registry.yaml
  ${VKPR_KUBECTL} config use-context k3d-vkpr-local
  else
    echoColor "bold" "$(echoColor "red" "Cluster vkpr-local already created.")"
  fi
  ${VKPR_KUBECTL} cluster-info
}

