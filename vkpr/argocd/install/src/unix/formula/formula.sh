#!/bin/bash

runFormula() {
  checkGlobalConfig "$DOMAIN" "localhost" "domain" "DOMAIN"
  checkGlobalConfig "$SECURE" "false" "secure" "SECURE"
  checkGlobalConfig "$HA" "false" "argocd.HA" "ARGOCD_HA"
  checkGlobalConfig "argocd" "argocd" "argocd.namespace" "ARGOCD_NAMESPACE"
  checkGlobalConfig "nginx" "nginx" "argocd.ingressClassName" "ARGOCD_INGRESS"
  checkGlobalConfig "false" "false" "argocd.metrics" "ARGOCD_METRICS"
  checkGlobalConfig "false" "false" "argocd.addons.applicationset" "ARGOCD_ADDONS_APPLICATIONSET"

  local VKPR_ENV_ARGOCD_DOMAIN="argocd.${VKPR_ENV_DOMAIN}"
  local VKPR_ARGOCD_VALUES; VKPR_ARGOCD_VALUES="$(dirname "$0")"/utils/argocd.yaml

  startInfos
  addRepoArgoCD
  installArgoCD
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR ArgoCD Install Routine")"
  echoColor "bold" "$(echoColor "blue" "ArgoCD Domain:") ${VKPR_ENV_ARGOCD_DOMAIN}"
  echoColor "bold" "$(echoColor "blue" "ArgoCD HTTPS:") ${VKPR_ENV_SECURE}"
  echoColor "bold" "$(echoColor "blue" "HA:") ${VKPR_ENV_ARGOCD_HA}"
  echoColor "bold" "$(echoColor "blue" "ArgoCD Admin Username:") admin"
  echoColor "bold" "$(echoColor "blue" "Ingress Controller:") ${VKPR_ENV_ARGOCD_INGRESS}"
  echo "=============================="
}

addRepoArgoCD(){
  registerHelmRepository argo https://argoproj.github.io/argo-helm
}

installArgoCD(){
  echoColor "bold" "$(echoColor "green" "Installing ArgoCD...")"
  local YQ_VALUES=".server.ingress.enabled = true"
  settingArgoCD

  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_ARGOCD_VALUES" \
  | $VKPR_HELM upgrade -i --version "$VKPR_ARGOCD_VERSION" \
    --namespace "$VKPR_ENV_ARGOCD_NAMESPACE" --create-namespace  \
    --wait -f - argocd argo/argo-cd

  settingArgoAddons
  printArgoPassword
}

printArgoPassword(){
  PASSWORD=$($VKPR_KUBECTL -n "$VKPR_ENV_ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
  echoColor "blue" "Your ArgoCD Super Admin password is ${PASSWORD}, we recommend that it be changed after the first login"
}

settingArgoCD(){
  YQ_VALUES="$YQ_VALUES |
    .server.ingress.hosts[0] = \"$VKPR_ENV_ARGOCD_DOMAIN\" |
    .server.config.url = \"$VKPR_ENV_ARGOCD_DOMAIN\" |
    .server.ingress.annotations.[\"kubernetes.io/ingress.class\"] = \"$VKPR_ENV_ARGOCD_INGRESS\"
  "

  if [[ "$VKPR_ENV_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .server.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .server.ingress.tls[0].secretName = \"argocd-cert\" |
      .server.ingress.tls[0].hosts[0] = \"$VKPR_ENV_ARGOCD_DOMAIN\" |
      .server.ingress.https = true
    "
  fi
  if [[ "$VKPR_ENV_ARGOCD_HA" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .controller.enableStatefulSet = true |
      .redis.enabled = true |
      .redis-ha.enabled = true |
      .redis-ha.exporter.enabled = false |
      .repoServer.replicas = 2 |
      .server.env[0].name = \"ARGOCD_API_SERVER_REPLICAS\" |
      .server.env[0].value = \"3\" |
      .server.replicas = 3
    "
  fi
  if [[ "$VKPR_ENV_ARGOCD_METRICS" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .controller.metrics.enabled = true |
      .controller.metrics.serviceMonitor.enabled = true |
      .controller.metrics.serviceMonitor.namespace = \"$VKPR_ENV_ARGOCD_NAMESPACE\" |
      .controller.metrics.serviceMonitor.interval = \"30s\" |
      .controller.metrics.serviceMonitor.scrapeTimeout = \"30s\" |
      .controller.metrics.serviceMonitor.additionalLabels.release = \"prometheus-stack\" |
      .server.metrics.enabled = true |
      .server.metrics.serviceMonitor.enabled = true |
      .server.metrics.serviceMonitor.namespace = \"$VKPR_ENV_ARGOCD_NAMESPACE\" |
      .server.metrics.serviceMonitor.interval = \"30s\" |
      .server.metrics.serviceMonitor.scrapeTimeout = \"30s\" |
      .server.metrics.serviceMonitor.additionalLabels.release = \"prometheus-stack\" 
    "
  fi

  mergeVkprValuesHelmArgs "argocd" "$VKPR_ARGOCD_VALUES"
}

settingArgoAddons(){
  if [[ "$VKPR_ENV_ARGOCD_ADDONS_APPLICATIONSET" == true ]]; then
    echoColor "bold" "$(echoColor "green" "Installing ArgoCD Addon Applicationset...")"

    local VKPR_ARGOCD_APPLICATIONSET_VALUES; VKPR_ARGOCD_APPLICATIONSET_VALUES="$(dirname "$0")"/utils/argocd-applicationset.yaml
    local YQ_APPLICATIONSET_VALUES; YQ_APPLICATIONSET_VALUES=".args.namespace = \"$VKPR_ENV_ARGOCD_NAMESPACE\""

    $VKPR_YQ eval "$YQ_APPLICATIONSET_VALUES" "$VKPR_ARGOCD_APPLICATIONSET_VALUES" \
    | $VKPR_HELM upgrade -i --version "$VKPR_ARGOCD_ADDON_APPLICATIONSET_VERSION" \
      --namespace "$VKPR_ENV_ARGOCD_NAMESPACE" --wait -f - argocd-applicationset argo/argocd-applicationset
  fi
}