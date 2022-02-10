#!/bin/bash

runFormula() {
  local VKPR_ARGOCD_VALUES=$(dirname "$0")/utils/argocd.yaml

  checkGlobalConfig $DOMAIN "localhost" "domain" "DOMAIN"
  checkGlobalConfig $SECURE "false" "secure" "SECURE"
  checkGlobalConfig $HA "false" "argocd.HA" "HA"
  checkGlobalConfig $ADMIN_PASSWORD "vkpr123" "argocd.adminPassword" "ARGOCD_ADMIN_PASSWORD"
  checkGlobalConfig "nginx" "nginx" "argocd.ingressClassName" "ARGOCD_INGRESS"
  checkGlobalConfig "false" "false" "argocd.metrics" "METRICS"
  checkGlobalConfig "false" "false" "argocd.addons.applicationset" "ARGO_ADDONS_APPLICATIONSET"

  local VKPR_ENV_ARGOCD_DOMAIN="argocd.${VKPR_ENV_DOMAIN}"

  startInfos
  addRepoArgoCD
  installArgoCD
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR ArgoCD Install Routine")"
  echoColor "bold" "$(echoColor "blue" "ArgoCD Domain:") ${VKPR_ENV_ARGOCD_DOMAIN}"
  echoColor "bold" "$(echoColor "blue" "ArgoCD HTTPS:") ${VKPR_ENV_SECURE}"
  echoColor "bold" "$(echoColor "blue" "HA:") ${VKPR_ENV_HA}"
  echoColor "bold" "$(echoColor "blue" "ArgoCD Admin Username:") admin"
  echoColor "bold" "$(echoColor "blue" "ArgoCD Admin Password:") ${VKPR_ENV_ARGOCD_ADMIN_PASSWORD}"
  echoColor "bold" "$(echoColor "blue" "Ingress Controller:") ${VKPR_ENV_ARGOCD_INGRESS}"
  echo "=============================="
}

addRepoArgoCD(){
  registerHelmRepository argo https://argoproj.github.io/argo-helm
}

installArgoCD(){
  local YQ_VALUES=".server.ingress.enabled = true"
  settingArgoCD
  echoColor "bold" "$(echoColor "green" "Installing ArgoCD...")"
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_ARGOCD_VALUES" \
  | $VKPR_HELM upgrade -i --version "$VKPR_ARGOCD_VERSION" \
    --create-namespace -n argocd \
    --wait --timeout 10m -f - argocd argo/argo-cd
  settingArgoAddons
}

settingArgoCD(){
  local ARGO_PASSWORD=$(htpasswd -nbBC 10 "" $VKPR_ENV_ARGOCD_ADMIN_PASSWORD | tr -d ':\n' | sed 's/$2y/$2a/')
  YQ_VALUES=''$YQ_VALUES' |
    .server.ingress.hosts[0] = "'$VKPR_ENV_ARGOCD_DOMAIN'" |
    .server.config.url = "'$VKPR_ENV_ARGOCD_DOMAIN'" |
    .server.ingress.annotations.["'kubernetes.io/ingress.class'"] = "'$VKPR_ENV_ARGOCD_INGRESS'" |
    .configs.secret.createSecret = "false" |
    .configs.secret.argocdServerAdminPassword = "'$ARGO_PASSWORD'"
  '
  if [[ $VKPR_ENV_SECURE = true ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .server.ingress.annotations.["'kubernetes.io/tls-acme'"] = "true" |
      .server.ingress.tls[0].secretName = "argocd-cert" |
      .server.ingress.tls[0].hosts[0] = "'$VKPR_ENV_ARGOCD_DOMAIN'" |
      .server.ingress.https = "true"
    '
  fi
  if [[ $VKPR_ENV_HA = true ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .controller.enableStatefulSet = "true" |
      .redis.enabled = "true" |
      .redis-ha.enabled = "true" |
      .redis-ha.exporter.enabled = "false" |
      .repoServer.replicas = 2 |
      .server.env[0].name = "ARGOCD_API_SERVER_REPLICAS" |
      .server.env[0].value = 3 |
      .server.replicas = 3
    '
  fi
  if [[ $VKPR_ENV_METRICS == "true" ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .controller.metrics.enabled = true |
      .controller.metrics.serviceMonitor.enabled = true |
      .controller.metrics.serviceMonitor.namespace = "vkpr" |
      .controller.metrics.serviceMonitor.interval = "30s" |
      .controller.metrics.serviceMonitor.scrapeTimeout = "30s" |
      .controller.metrics.serviceMonitor.additionalLabels.release = "prometheus-stack" |
      .server.metrics.enabled = true |
      .server.metrics.serviceMonitor.enabled = true |
      .server.metrics.serviceMonitor.namespace = "vkpr" |
      .server.metrics.serviceMonitor.interval = "30s" |
      .server.metrics.serviceMonitor.scrapeTimeout = "30s" |
      .server.metrics.serviceMonitor.additionalLabels.release = "prometheus-stack" 
    '
  fi

  mergeVkprValuesHelmArgs "argocd" $VKPR_ARGOCD_VALUES
}

settingArgoAddons(){
  if [[ $VKPR_ENV_ARGO_ADDONS_APPLICATIONSET = true ]]; then
    echoColor "bold" "$(echoColor "green" "Installing ArgoCD Addon Applicationset...")"
    $VKPR_KUBECTL apply -n argocd \
      -f https://raw.githubusercontent.com/argoproj-labs/applicationset/$VKPR_ARGOCD_ADDON_APPLICATIONSET_VERSION/manifests/install.yaml
  fi
}