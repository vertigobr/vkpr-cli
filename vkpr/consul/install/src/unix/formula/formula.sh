#!/usr/bin/env bash

runFormula() {
  local VKPR_ENV_CONSUL_DOMAIN VKPR_CONSUL_VALUES HELM_ARGS;
  formulaInputs
  validateInputs

  VKPR_ENV_CONSUL_DOMAIN="consul.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_CONSUL_VALUES=$(dirname "$0")/utils/consul.yaml

  startInfos
  settingConsul
  [ $DRY_RUN = false ] && registerHelmRepository hashicorp https://helm.releases.hashicorp.com
  installApplication "consul" "hashicorp/consul" "$VKPR_ENV_CONSUL_NAMESPACE" "$VKPR_CONSUL_VERSION" "$VKPR_CONSUL_VALUES" "$HELM_ARGS"
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Consul Install Routine"
  boldNotice "Domain: $VKPR_ENV_CONSUL_DOMAIN"
  boldNotice "Secure: $VKPR_ENV_GLOBAL_SECURE"
  boldNotice "Namespace: $VKPR_ENV_CONSUL_NAMESPACE"
  boldNotice "Ingress Controller: $VKPR_ENV_CONSUL_INGRESS_CLASS_NAME"
  bold "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "consul.ingressClassName" "CONSUL_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "consul.namespace" "CONSUL_NAMESPACE"
  checkGlobalConfig "false" "false" "consul.metrics" "CONSUL_METRICS"
  checkGlobalConfig "$SSL" "false" "consul.ssl.enabled" "CONSUL_SSL"
  checkGlobalConfig "$CRT_FILE" "" "consul.ssl.crt" "CONSUL_SSL_CERTIFICATE"
  checkGlobalConfig "$KEY_FILE" "" "consul.ssl.key" "CONSUL_SSL_KEY"
  checkGlobalConfig "" "" "consul.ssl.secretName" "CONSUL_SSL_SECRET"

  # External app values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "GRAFANA_NAMESPACE"
}

validateInputs() {
  validateConsulDomain "$VKPR_ENV_GLOBAL_DOMAIN"
  validateConsulSecure "$VKPR_ENV_GLOBAL_SECURE"

  validateConsulIngressClassName "$VKPR_ENV_CONSUL_INGRESS_CLASS_NAME"
  validateConsulNamespace "$VKPR_ENV_CONSUL_NAMESPACE"
  validateConsulSsl "$VKPR_ENV_CONSUL_SSL"
  if [[ "$VKPR_ENV_CONSUL_SSL" == true ]]; then
    validateConsulSslCrtPath "$VKPR_ENV_CONSUL_SSL_CERTIFICATE"
    validateConsulSslKeyPath "$VKPR_ENV_CONSUL_SSL_KEY"
  fi
}

settingConsul() {
  YQ_VALUES=".ui.ingress.hosts[0].host = \"$VKPR_ENV_CONSUL_DOMAIN\" |
   .ui.ingress.ingressClassName = \"$VKPR_ENV_CONSUL_INGRESS_CLASS_NAME\"
  "

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .ui.ingress.tls[0].hosts[0] = \"$VKPR_ENV_CONSUL_DOMAIN\" |
      .ui.ingress.tls[0].secretName = \"consul-cert\"
    "
    else
    YQ_VALUES="$YQ_VALUES |
      .ui.ingress.annotations = \"\"
    "
  fi

  if [[ "$VKPR_ENV_CONSUL_METRICS" == true ]] && [[ $(checkPodName "$VKPR_ENV_GRAFANA_NAMESPACE" "prometheus-stack-grafana") == "true" ]]; then
    $VKPR_KUBECTL apply -n $VKPR_ENV_CONSUL_NAMESPACE -f $(dirname "$0")/utils/servicemonitor.yaml
    createGrafanaDashboard "$(dirname "$0")/utils/dashboard.json" "$VKPR_ENV_GRAFANA_NAMESPACE"
    YQ_VALUES="$YQ_VALUES |
      .global.metrics.enabled = true |
      .global.metrics.enableAgentMetrics = true |
      .global.metrics.agentMetricsRetentionTime = \"72h\"
    "
  fi

  if [[ "$VKPR_ENV_CONSUL_SSL" == "true" ]]; then
    if [[ "$VKPR_ENV_CONSUL_SSL_SECRET" == "" ]]; then
      VKPR_ENV_CONSUL_SSL_SECRET="consul-certificate"
      $VKPR_KUBECTL create secret tls $VKPR_ENV_CONSUL_SSL_SECRET -n "$VKPR_ENV_CONSUL_NAMESPACE" \
        --cert="$VKPR_ENV_CONSUL_SSL_CERTIFICATE" \
        --key="$VKPR_ENV_CONSUL_SSL_KEY"
    fi
    YQ_VALUES="$YQ_VALUES |
      .ui.ingress.tls[0].hosts[0] = \"$VKPR_ENV_CONSUL_DOMAIN\" |
      .ui.ingress.tls[0].secretName = \"$VKPR_ENV_CONSUL_SSL_SECRET\"
     "
  fi

  settingConsulEnvironment

  debug "YQ_CONTENT = $YQ_VALUES"
}

settingConsulEnvironment() {
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    #YQ_VALUES="$YQ_VALUES"
  fi
}
