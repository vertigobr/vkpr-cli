#!/bin/bash


runFormula() {
  local VKPR_INGRESS_VALUES HELM_ARGS;
  formulaInputs
  #validateInputs

  VKPR_INGRESS_VALUES="$(dirname "$0")"/utils/ingress.yaml
  
  startInfos
  settingIngress
  [ $DRY_RUN = false ] && registerHelmRepository ingress-nginx https://kubernetes.github.io/ingress-nginx
  installApplication "ingress-nginx" "ingress-nginx/ingress-nginx" "$VKPR_ENV_INGRESS_NAMESPACE" "$VKPR_INGRESS_NGINX_VERSION" "$VKPR_INGRESS_VALUES" "$HELM_ARGS"
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Ingress Install Routine"
  bold "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "$LB_TYPE" "Classic" "ingress.loadBalancerType" "INGRESS_LB_TYPE"
  checkGlobalConfig "false" "false" "ingress.metrics" "INGRESS_METRICS"
  checkGlobalConfig "$SSL" "false" "ingress.ssl.enabled" "INGRESS_SSL"
  checkGlobalConfig "nginx-cert" "nginx-cert" "ingress.ssl.secretName" "INGRESS_SSL_SECRET"
  checkGlobalConfig "$CRT_FILE" "" "ingress.ssl.crt" "INGRESS_CERTIFICATE"
  checkGlobalConfig "$KEY_FILE" "" "ingress.ssl.key" "INGRESS_KEY"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "ingress.namespace" "INGRESS_NAMESPACE"
}

#validateInputs() {}

settingIngress() {
  YQ_VALUES=".rbac.create = true"

  if [[ "$VKPR_ENV_INGRESS_LB_TYPE" == "NLB" ]]; then
    YQ_VALUES="
      .controller.service.annotations.[\"service.beta.kubernetes.io/aws-load-balancer-backend-protocol\"] = \"tcp\" |
      .controller.service.annotations.[\"service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled\"] = \"true\" |
      .controller.service.annotations.[\"service.beta.kubernetes.io/aws-load-balancer-type\"] = \"nlb\"
    "
  fi

  if [[ "$VKPR_ENV_INGRESS_METRICS" == "true" ]]; then
    YQ_VALUES="$YQ_VALUES |
      .controller.metrics.enabled = true |
      .controller.metrics.service.annotations.[\"prometheus.io/scrape\"] = \"true\" |
      .controller.metrics.service.annotations.[\"prometheus.io/port\"] = \"10254\" |
      .controller.metrics.serviceMonitor.enabled = true |
      .controller.metrics.serviceMonitor.namespace = \"$VKPR_ENV_INGRESS_NAMESPACE\" |
      .controller.metrics.serviceMonitor.additionalLabels.release = \"prometheus-stack\"
     "
  fi

  if [[ "$VKPR_ENV_INGRESS_SSL" == "true" ]]; then
    [[ "$VKPR_ENV_INGRESS_SSL_SECRET" == "nginx-cert" ]] && $VKPR_KUBECTL create secret tls nginx-cert -n "$VKPR_ENV_INGRESS_NAMESPACE" \
      --cert="$VKPR_ENV_INGRESS_CERTIFICATE" \
      --key="$VKPR_ENV_INGRESS_KEY"
    YQ_VALUES="$YQ_VALUES |
      .controller.extraArgs.default-ssl-certificate = \"$VKPR_ENV_INGRESS_NAMESPACE/$VKPR_ENV_INGRESS_SSL_SECRET\"
     "
  fi

  settingIngressEnvironment

  debug "YQ_CONTENT = $YQ_VALUES"
}

settingIngressEnvironment() {
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    YQ_VALUES="$YQ_VALUES |
      .ingress.enabled = false |
      .service.annotations.[\"dev.okteto.com/auto-ingress\"] = \"true\"
    "
  fi
}