#!/bin/sh

runFormula() {
  VKPR_EXTERNAL_LOKI_VALUES=$(dirname "$0")/utils/loki.yaml

  addRepLoki
  installLoki
}

addRepLoki(){
    echoColor "green" "Installing Loki..."
    $VKPR_HELM repo add grafana https://grafana.github.io/helm-charts
    $VKPR_HELM repo update
  }

  installLoki(){
     $VKPR_HELM upgrade --install vkpr-loki-stack -f $VKPR_EXTERNAL_LOKI_VALUES grafana/loki-stack
  }


