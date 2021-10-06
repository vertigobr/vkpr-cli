#!/bin/sh

runFormula() {
  VKPR_EXTERNAL_LOKI_VALUES=$(dirname "$0")/utils/loki.yaml

  addRepLoki
  installLoki
  existGrafana
}

addRepLoki(){
    echoColor "green" "Installing Loki..."
    registerHelmRepository grafana https://grafana.github.io/helm-charts
}

installLoki(){
  $VKPR_HELM upgrade --install \
    --namespace $VKPR_K8S_NAMESPACE --create-namespace \
    --wait --timeout 5m \
    loki-stack -f $VKPR_EXTERNAL_LOKI_VALUES grafana/loki-stack
}

existGrafana() {
  if [[ $(checkExistingGrafana) = "vkpr-prometheus-stack-grafana" ]]; then
    local LOGINGRAFANA="$($VKPR_KUBECTL get secret --namespace $VKPR_K8S_NAMESPACE vkpr-prometheus-stack-grafana -o yaml | $VKPR_YQ eval '.data.admin-user' - | base64 -d):$($VKPR_KUBECTL get secret --namespace $VKPR_K8S_NAMESPACE vkpr-prometheus-stack-grafana -o yaml | $VKPR_YQ eval '.data.admin-password' - | base64 -d)"
    local TOKEN_API_GRAFANA=$(curl -k -X POST -H "Host: grafana.localhost" -H "Content-Type: application/json" -d '{"name": "apikeycurl","role": "Admin"}' http://$LOGINGRAFANA@127.0.0.1:8000/api/auth/keys | $VKPR_JQ --raw-output '.key')
    if [[ $TOKEN_API_GRAFANA == "" ]]; then
      echoColor "red" "Api Token can only be request once or ingress is not installed."
    fi
    curl -K -X -H "Host: grafana.localhost" -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN_API_GRAFANA" -d '
      {
        "name":"loki",
        "type":"loki",
        "url":"vkpr-loki-stack.'$VKPR_K8S_NAMESPACE'.svs.cluster.local:3100",
        "access":"proxy",
        "basicAuth":false,
        "editable": true
      }' http://127.0.0.1:8000/api/datasources
  fi
}