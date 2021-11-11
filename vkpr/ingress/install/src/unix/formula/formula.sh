#!/bin/sh


runFormula() {
  local VKPR_INGRESS_VALUES=$(dirname "$0")/utils/ingress.yaml
  echoColor "green" "Installing Nginx Ingress..."
  
  checkGlobalConfig $LB_TYPE "ingress.lb_type" "Classic" "LB_TYPE"
  checkGlobal "ingress.resources" $VKPR_INGRESS_VALUES "resources"
  checkGlobal "ingress.extraEnv" $VKPR_INGRESS_VALUES
  
  configureRepository
  installIngress
}

configureRepository() {
  registerHelmRepository nginx-stable https://helm.nginx.com/stable
}

installIngress() {
  settingIngress
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_INGRESS_VALUES" \
  | $VKPR_HELM upgrade -i --version "$VKPR_INGRESS_NGINX_VERSION" \
      --namespace $VKPR_K8S_NAMESPACE --create-namespace \
      --wait --timeout 60s -f - ingress-nginx nginx-stable/nginx-ingress
}

settingIngress() {
  if [[ $VKPR_ENV_LB_TYPE == "NLB" ]]; then
    YQ_VALUES='
      .controller.service.annotations.["'service.beta.kubernetes.io/aws-load-balancer-backend-protocol'"] = "tcp" |
      .controller.service.annotations.["'service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled'"] = "'true'" |
      .controller.service.annotations.["'service.beta.kubernetes.io/aws-load-balancer-type'"] = "nlb"
    '
  fi
}