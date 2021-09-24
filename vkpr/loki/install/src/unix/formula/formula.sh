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
     $VKPR_HELM upgrade --install --wait --timeout 5m vkpr-loki-stack -f $VKPR_EXTERNAL_LOKI_VALUES grafana/loki-stack
  }

  existGrafana(){
    check_pod_name "vkpr-prometheus-stack-grafana" 
    if [[ $POD_EXISTS == true ]]; then
      echoColor "yellow" "Adding Loki to Grafana's datasource..."
      local LOGINGRAFANA="$($VKPR_KUBECTL get secret vkpr-prometheus-stack-grafana -o yaml | $VKPR_YQ eval '.data.admin-user' - | base64 -d):$($VKPR_KUBECTL get secret vkpr-prometheus-stack-grafana -o yaml | $VKPR_YQ eval '.data.admin-password' - | base64 -d)"
      local TOKEN_API_GRAFANA=$(curl -k -X POST -H "Host: grafana.localhost" -H "Content-Type: application/json" -d '{"name": "apikeycurl","role": "Admin"}' http://$LOGINGRAFANA@127.0.0.1:8000/api/auth/keys | $VKPR_JQ --raw-output '.key')
      if [[ $TOKEN_API_GRAFANA == "" ]]; then
        echoColor "red" "Api Token can only be request once or ingress is not installed."
      fi

        curl -K -X -H "Host: grafana.localhost" -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN_API_GRAFANA" -d '
            {
              "name":"loki",
              "type":"loki",
              "url":"vkpr-loki-stack.default.svs.cluster.local:3100",
              "access":"proxy",
              "basicAuth":false,
              "editable": true
            }' http://127.0.0.1:8000/api/datasources

    fi
  }

  check_pod_name(){
    for pod in $($VKPR_KUBECTL get pods | awk 'NR>1{print $1}'); do
      if [[ "$pod" == "$1"* ]]; then
        POD_EXISTS=true  # pod name found a match, then returns True
        return
      fi
    done
    POD_EXISTS=false
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

