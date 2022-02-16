#!/bin/sh


runFormula() {
  local VKPR_INGRESS_VALUES=$(dirname "$0")/utils/ingress.yaml
  
  checkGlobalConfig $LB_TYPE "Classic" "ingress.loadBalancerType" "LB_TYPE"
  checkGlobalConfig "false" "false" "ingress.metrics" "METRICS"
  checkGlobalConfig $VKPR_K8S_NAMESPACE "vkpr" "ingress.namespace" "NAMESPACE"

  startInfos
  configureRepository
  installIngress
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Ingress Install Routine")"
  echo "=============================="
}

configureRepository() {
  registerHelmRepository ingress-nginx https://kubernetes.github.io/ingress-nginx
}

installIngress() {
  echoColor "bold" "$(echoColor "green" "Installing ngnix ingress...")"
  local YQ_VALUES=".rbac.create = true"
  settingIngress
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_INGRESS_VALUES" \
  | $VKPR_HELM upgrade -i --version "$VKPR_INGRESS_NGINX_VERSION" \
      --namespace $VKPR_ENV_NAMESPACE --create-namespace \
      --wait --timeout 5m0s -f - ingress-nginx ingress-nginx/ingress-nginx
}

settingIngress() {
  if [[ $VKPR_ENV_LB_TYPE == "NLB" ]]; then
    YQ_VALUES='
      .controller.service.annotations.["'service.beta.kubernetes.io/aws-load-balancer-backend-protocol'"] = "tcp" |
      .controller.service.annotations.["'service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled'"] = "'true'" |
      .controller.service.annotations.["'service.beta.kubernetes.io/aws-load-balancer-type'"] = "nlb"
    '
  fi

  if [[ $VKPR_ENV_METRICS = "true" ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .controller.metrics.enabled = "true" |
      .controller.metrics.service.annotations.["'prometheus.io/scrape'"] = "true" |
      .controller.metrics.service.annotations.["'prometheus.io/port'"] = "10254" |
      .controller.metrics.serviceMonitor.enabled = "true" |
      .controller.metrics.serviceMonitor.namespace = "'$VKPR_ENV_NAMESPACE'" |
      .controller.metrics.serviceMonitor.additionalLabels.release = "prometheus-stack"
    ' 
  fi

  mergeVkprValuesHelmArgs "ingress" $VKPR_INGRESS_VALUES
}