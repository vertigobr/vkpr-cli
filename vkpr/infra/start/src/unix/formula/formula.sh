#!/bin/bash


runFormula() {
  checkGlobalConfig "$HTTP_PORT" "8000" "infra.httpPort" "HTTP_PORT"
  checkGlobalConfig "$HTTPS_PORT" "8001" "infra.httpsPort" "HTTPS_PORT"
  checkGlobalConfig "$ENABLE_TRAEFIK" "false" "infra.traefik.enabled" "TRAEFIK"
  checkGlobalConfig "1" "1" "infra.resources.masters" "K3D_SERVERS"
  checkGlobalConfig "$WORKER_NODES" "1" "infra.resources.workers" "K3D_AGENTS"

  startInfos
  configRegistry
  startRegistry
  startCluster
}

startInfos() {
  echo "=============================="
  info "VKPR Local Infra Start Routine"
  notice "Enabled Traefik Ingress Controller: ${VKPR_ENV_TRAEFIK}"
  notice "Ports Used:" ":${VKPR_ENV_HTTP_PORT}/http :${VKPR_ENV_HTTPS_PORT}/https"
  notice "Kubernetes API:" ":6443"
  notice "Local Registry: :6000"
  notice "Docker Hub Registry Mirror (cache): :6001"
  warn "Using two local unamed Docker Volumes"
  echo "=============================="
  
}

configRegistry() {
  #local HOST_IP="172.17.0.1"  #Linux Native
  local HOST_IP="host.k3d.internal"
  cat > "${VKPR_CONFIG}"/registry.yaml << EOF
mirrors:
  "docker.io":
    endpoint:
      - "http://$HOST_IP:6001"
EOF
debug "Calling the function configRegistry"
}

# Create the local registry and Docker Hub Mirror
startRegistry() {
  if ! ${VKPR_K3D} registry list | grep -q "k3d-registry\.localhost"; then
    ${VKPR_K3D} registry create registry.localhost -p 6000
  else
    warn "Registry already started, skipping..."
  fi

  if ! ${VKPR_K3D} registry list | grep -q "k3d-mirror\.localhost"; then
    ${VKPR_K3D} registry create mirror.localhost -i vertigo/registry-mirror -p 6001
  else
    warn "Mirror already started, skipping..."
  fi
  debug "Calling the function startRegistry"
}

# Starts K8S using Registries
startCluster() {
  local TRAEFIK_FLAG=""

  if [ "${ENABLE_TRAEFIK}" == false ]; then
    TRAEFIK_FLAG="--disable=traefik@server:0"
  fi

  if ! ${VKPR_K3D} cluster list | grep -q "vkpr-local"; then
    ${VKPR_K3D} cluster create vkpr-local \
      -s "${VKPR_ENV_K3D_SERVERS}" -a "${VKPR_ENV_K3D_AGENTS}" \
      -p "${VKPR_ENV_HTTP_PORT}:80@loadbalancer" \
      -p "${VKPR_ENV_HTTPS_PORT}:443@loadbalancer" \
      --k3s-arg "${TRAEFIK_FLAG}" \
      --registry-use k3d-registry.localhost \
      --registry-config "${VKPR_CONFIG}"/registry.yaml
  ${VKPR_KUBECTL} config use-context k3d-vkpr-local
  else
    error "Cluster vkpr-local already created."
  fi

  ${VKPR_KUBECTL} cluster-info
}

