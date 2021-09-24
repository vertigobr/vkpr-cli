#!/bin/sh

runFormula() {
  VKPR_EXTERNAL_LOKI_VALUES=$(dirname "$0")/utils/loki.yaml

  addRepLoki
  installLoki
  existGrafana
}

addRepLoki(){
  echoColor "green" "Installing Loki..."
  $VKPR_HELM repo add grafana https://grafana.github.io/helm-charts
  $VKPR_HELM repo update
}

installLoki(){
  $VKPR_HELM upgrade --wait --install vkpr-loki-stack -f $VKPR_EXTERNAL_LOKI_VALUES grafana/loki-stack
}


existGrafana() {
  if [[ $(checkExistingGrafana) = "vkpr-prometheus-stack-grafana" ]]; then
    local LOGINGRAFANA="$($VKPR_KUBECTL get secret vkpr-prometheus-stack-grafana -o yaml | $VKPR_YQ eval '.data.admin-user' - | base64 -d):$($VKPR_KUBECTL get secret vkpr-prometheus-stack-grafana -o yaml | $VKPR_YQ eval '.data.admin-password' - | base64 -d)"
    local TOKEN_API_GRAFANA=$(curl -sk -X POST -H "Host: grafana.localhost" \
    -H "Content-Type: application/json" \
    -d '
      {
        "name":"apikeycurl",
        "role": "Admin"
      }
    ' http://$LOGINGRAFANA@127.0.0.1:8000/api/auth/keys | $VKPR_JQ --raw-output '.key')
    curl -sk -X POST -H "Host: grafana.localhost" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN_API_GRAFANA" \
    -d '
      {
        "name":"Loki",
        "type":"loki",
        "url":"http://vkpr-loki-stack:3100",
        "access":"proxy",
        "basicAuth":false,
        "editable": true
      }
    ' http://127.0.0.1:8000/api/datasources > /dev/null
  fi
}

