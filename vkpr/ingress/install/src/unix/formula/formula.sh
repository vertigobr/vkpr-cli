#!/bin/sh


runFormula() {
  local VKPR_INGRESS_VALUES=$(dirname "$0")/utils/ingress.yaml
  echoColor "green" "Installing Nginx Ingress..."
  
  checkGlobal "ingress.resources" $VKPR_INGRESS_VALUES "resources"
  checkGlobal "ingress.extraEnv" $VKPR_INGRESS_VALUES

  configureRepository
  installIngress
}

configureRepository() {
  registerHelmRepository nginx-stable https://helm.nginx.com/stable
}

installIngress() {
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_INGRESS_VALUES" \
  | $VKPR_HELM upgrade -i --version "$VKPR_INGRESS_NGINX_VERSION" \
      --namespace $VKPR_K8S_NAMESPACE --create-namespace \
      --wait --timeout 60s -f - ingress-nginx nginx-stable/nginx-ingress
}
