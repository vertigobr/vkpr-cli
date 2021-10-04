#!/bin/sh


runFormula() {
  echoColor "green" "Installing Nginx Ingress..."
  configureRepository
  installIngress
}

configureRepository() {
  registerHelmRepository nginx-stable https://helm.nginx.com/stable
}

installIngress() {
  $VKPR_HELM upgrade -i vkpr-ingress nginx-stable/nginx-ingress \
      --namespace $VKPR_K8S_NAMESPACE --create-namespace \
      --wait --timeout 60s
}
