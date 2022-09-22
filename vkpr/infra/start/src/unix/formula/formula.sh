#!/usr/bin/env bash


runFormula() {
  local APP_VALUES=$(dirname "$0")/utils/kube.yaml

  formulaInputs
  validateInputs

  VKPR_ENV_NUMBER_NODEPORTS=$((VKPR_ENV_NUMBER_NODEPORTS-1))

  startInfos
  startRegistry
  configureCluster
  startCluster
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Local Infra Start Routine"
  boldNotice "Enabled Traefik Ingress Controller: ${VKPR_ENV_TRAEFIK}"
  boldNotice "Ports Used: ${VKPR_ENV_HTTP_PORT}/http :${VKPR_ENV_HTTPS_PORT}/https"
  boldNotice "Kubernetes API: 6443"
  boldNotice "Local Registry: 6000"
  boldNotice "Docker Hub Registry Mirror (cache): 6001"
  boldNotice "NodePorts available: 9000-$((VKPR_ENV_NUMBER_NODEPORTS+9000)):30000-$((VKPR_ENV_NUMBER_NODEPORTS+30000))"
  boldWarn "Using two local unamed Docker Volumes"
  bold "=============================="
}

formulaInputs() {
  # app values
  checkGlobalConfig "$HTTP_PORT" "8000" "infra.httpPort" "HTTP_PORT"
  checkGlobalConfig "$HTTPS_PORT" "8001" "infra.httpsPort" "HTTPS_PORT"
  checkGlobalConfig "$ENABLE_TRAEFIK" "false" "infra.enableTraefik" "TRAEFIK"
  checkGlobalConfig "1" "1" "infra.resources.masters" "K3D_SERVERS"
  checkGlobalConfig "$WORKER_NODES" "1" "infra.resources.workers" "K3D_AGENTS"
  checkGlobalConfig "$ENABLE_VOLUME" "false" "infra.enableVolume" "VOLUME"
  checkGlobalConfig "$NODEPORTS" "0" "infra.nodePorts" "NUMBER_NODEPORTS"
}

validateInputs() {
  validateInfraHTTP "$VKPR_ENV_HTTP_PORT"
  validateInfraHTTPS "$VKPR_ENV_HTTPS_PORT"
  validateInfraNodes "$VKPR_ENV_K3D_AGENTS"
  validateInfraTraefik "$VKPR_ENV_TRAEFIK"
  validateInfraNodePorts "$VKPR_ENV_NUMBER_NODEPORTS"
}

# Create the local registry and Docker Hub Mirror
startRegistry() {
  if ! ${VKPR_K3D} registry list | grep -q "k3d-registry\.localhost"; then
    ${VKPR_K3D} registry create registry.localhost \
      -p 6000 -v vkpr-registry:/var/lib/registry
  else
    warn "Registry already started, skipping..."
  fi

  if ! ${VKPR_K3D} registry list | grep -q "k3d-mirror\.localhost"; then
    ${VKPR_K3D} registry create mirror.localhost -i vertigo/registry-mirror \
      -p 6001 -v vkpr-mirror-registry:/var/lib/registry
  else
    warn "Mirror already started, skipping..."
  fi
}

# Starts K8S using Registries
startCluster() {
  if $VKPR_K3D cluster list | grep -q "vkpr-local"; then
    error "Cluster vkpr-local already created."
    return
  fi

  $VKPR_YQ eval -i "$YQ_VALUES" "$APP_VALUES"
  mergeVkprValuesHelmArgs "infra" "$APP_VALUES"
  $VKPR_K3D cluster create --config $APP_VALUES
  $VKPR_KUBECTL cluster-info
}

configureCluster() {
  YQ_VALUES=".servers = $VKPR_ENV_K3D_SERVERS |
    .agents = $VKPR_ENV_K3D_AGENTS |
    .ports[0].port = \"$VKPR_ENV_HTTP_PORT:80\" |
    .ports[1].port = \"$VKPR_ENV_HTTPS_PORT:443\"
  "

  if [ $NODEPORTS -gt 0 ] ; then
    local PORT_LOCAL="$((VKPR_ENV_NUMBER_NODEPORTS+9000))" \
          PORT_NODE="$((VKPR_ENV_NUMBER_NODEPORTS+30000))"
    YQ_VALUES="$YQ_VALUES |
      .ports[2].port = \"9000-$PORT_LOCAL:30000-$PORT_NODE\" |
      .ports[2].nodeFilters[0] = \"agent:0\"
    "
  fi

  if [ "$VKPR_ENV_TRAEFIK" == false ]; then
    YQ_VALUES="$YQ_VALUES |
      .options.k3s.extraArgs[0].arg = \"--disable=traefik\" |
      .options.k3s.extraArgs[0].nodeFilters[0] = \"server:*\"
    "
  fi

  if [ "$VKPR_ENV_VOLUME" == true ]; then
    mkdir -p /tmp/k3dvol
    YQ_VALUES="$YQ_VALUES |
      .volumes[0].volume = \"/tmp/k3dvol:/tmp/k3dvol\" |
      .volumes[0].nodeFilters[0] = \"agent:*\"
    "
  fi
}
