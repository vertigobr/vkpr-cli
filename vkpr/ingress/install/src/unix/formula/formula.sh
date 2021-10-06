#!/bin/sh


runFormula() {
<<<<<<< HEAD
  echo "VKPR Ingress install"
  $VKPR_ARKADE install ingress-nginx -n vkpr --wait
=======
  echoColor "green" "Installing Nginx Ingress..."
  
  configureRepository
  installIngress
}

configureRepository() {
  registerHelmRepository nginx-stable https://helm.nginx.com/stable
}

installIngress() {
  $VKPR_HELM upgrade -i ingress-nginx nginx-stable/nginx-ingress \
    -n $VKPR_K8S_NAMESPACE --create-namespace \
    --wait --timeout 60s
>>>>>>> origin/stage
}
