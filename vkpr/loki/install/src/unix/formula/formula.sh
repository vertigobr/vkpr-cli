#!/bin/sh

runFormula() {
  local VKPR_LOKI_VALUES=$(dirname "$0")/utils/loki.yaml
  local DOMAIN="localhost"

  checkGlobalConfig $DOMAIN "localhost" "domain" "DOMAIN"

  startInfos
  addRepLoki
  installLoki
  existGrafana
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Loki Install Routine")"
  echo "=============================="
}

addRepLoki(){
  registerHelmRepository grafana https://grafana.github.io/helm-charts
}

installLoki(){
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_LOKI_VALUES" \
  | $VKPR_HELM upgrade -i --version "$VKPR_LOKI_VERSION" \
    --create-namespace --namespace $VKPR_K8S_NAMESPACE\
    --wait -f - loki-stack grafana/loki-stack
}

existGrafana() {
  if [[ $(checkPodName "prometheus-stack-grafana") = "true" ]]; then
    local LOGINGRAFANA="$($VKPR_KUBECTL get secret --namespace $VKPR_K8S_NAMESPACE prometheus-stack-grafana -o yaml \
                          | $VKPR_YQ eval '.data.admin-user' - | base64 -d):$($VKPR_KUBECTL get secret --namespace $VKPR_K8S_NAMESPACE prometheus-stack-grafana -o yaml | $VKPR_YQ eval '.data.admin-password' - | base64 -d)"

    local TOKEN_API_GRAFANA=$(curl -sk -X POST -H "Host: grafana.${VKPR_ENV_DOMAIN}" -H "Content-Type: application/json" \
                              -d '{"name": "apikeycurl","role": "Admin"}' http://$LOGINGRAFANA@127.0.0.1:8000/api/auth/keys | $VKPR_JQ --raw-output '.key')

    if [[ $TOKEN_API_GRAFANA == "" ]]; then
      echoColor "red" "Api Token can only be request once or ingress is not installed."
    fi

    curl -sK -X \
    -H "Host: grafana.$VKPR_ENV_DOMAIN" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN_API_GRAFANA" \
    -d '{
          "name":"loki",
          "type":"loki",
          "url":"loki-stack.'$VKPR_K8S_NAMESPACE'.svs.cluster.local:3100",
          "access":"proxy",
          "basicAuth":false,
          "editable": true
        }' http://127.0.0.1:8000/api/datasources
  fi
}