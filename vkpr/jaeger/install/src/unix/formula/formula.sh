#!/usr/bin/env bash
source "$(dirname "$0")"/unix/formula/objects.sh

runFormula() {
  local VKPR_ENV_JAEGER_DOMAIN VKPR_JAEGER_VALUES HELM_ARGS;
  formulaInputs
  validateInputs

  VKPR_ENV_JAEGER_DOMAIN="jaeger.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_JAEGER_VALUES=$(dirname "$0")/utils/jaeger.yaml

  startInfos
  settingJaeger
  [ $DRY_RUN = false ] && registerHelmRepository jaegertracing https://jaegertracing.github.io/helm-charts
  installApplication "jaeger" "jaegertracing/jaeger" "$VKPR_ENV_JAEGER_NAMESPACE" "$VKPR_JAEGER_VERSION" "$VKPR_JAEGER_VALUES" "$HELM_ARGS"
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Jaeger Install Routine"
  boldNotice "Domain: $VKPR_ENV_JAEGER_DOMAIN"
  boldNotice "Secure: $VKPR_ENV_GLOBAL_SECURE"
  boldNotice "Namespace: $VKPR_ENV_JAEGER_NAMESPACE"
  boldNotice "Ingress Controller: $VKPR_ENV_JAEGER_INGRESS_CLASS_NAME"
  bold "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "jaeger.ingressClassName" "JAEGER_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "jaeger.namespace" "JAEGER_NAMESPACE"
  checkGlobalConfig "false" "false" "jaeger.persistence" "JAEGER_PERSISTENCE"
  checkGlobalConfig "false" "false" "jaeger.metrics" "JAEGER_METRICS"
  checkGlobalConfig "$SSL" "false" "jaeger.ssl.enabled" "JAEGER_SSL"
  checkGlobalConfig "$CRT_FILE" "" "jaeger.ssl.crt" "JAEGER_SSL_CERTIFICATE"
  checkGlobalConfig "$KEY_FILE" "" "jaeger.ssl.key" "JAEGER_SSL_KEY"
  checkGlobalConfig "" "" "jaeger.ssl.secretName" "JAEGER_SSL_SECRET"

  # External apps values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "GRAFANA_NAMESPACE"
}

validateInputs() {

  validateJaegerDomain "$VKPR_ENV_GLOBAL_DOMAIN"
  validateJaegerSecure "$VKPR_ENV_GLOBAL_SECURE"
  validateJaegerMetrics "$VKPR_ENV_JAEGER_METRICS"

  validateJaegerIngressClassName "$VKPR_ENV_JAEGER_INGRESS_CLASS_NAME"
  validateJaegerNamespace "$VKPR_ENV_JAEGER_NAMESPACE"
  validateJaegerPersistance "$VKPR_ENV_JAEGER_PERSISTENCE"

  validateJaegerSsl "$VKPR_ENV_JAEGER_SSL"
  if [[ $VKPR_ENV_JAEGER_SSL == true ]]; then
    validateJaegerSslCrtPath "$VKPR_ENV_JAEGER_SSL_CERTIFICATE"
    validateJaegerSslKeyPath "$VKPR_ENV_JAEGER_SSL_KEY"
  fi
}

settingJaeger() {
  YQ_VALUES=".allInOne.ingress.hosts[0] = \"$VKPR_ENV_JAEGER_DOMAIN\" |
    .allInOne.ingress.ingressClassName = \"$VKPR_ENV_JAEGER_INGRESS_CLASS_NAME\"
  "
  # if [[ "$VKPR_ENV_JAEGER_METRICS" == true ]] && [[ $(checkPodName "$VKPR_ENV_GRAFANA_NAMESPACE" "prometheus-stack-grafana") == "true" ]]; then
  #   createGrafanaDashboard "$(dirname "$0")/utils/dashboard.json" "$VKPR_ENV_GRAFANA_NAMESPACE"
  #   YQ_VALUES="$YQ_VALUES |
  #     .query.serviceMonitor.enabled= true |
  #     .query.serviceMonitor.additionalLabels.release = \"prometheus-stack\"
  #   "
  # fi

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .allInOne.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .allInOne.ingress.tls[0].hosts[0] = \"$VKPR_ENV_JAEGER_DOMAIN\" |
      .allInOne.ingress.tls[0].secretName = \"jaeger-cert\"
    "
  fi

  if [[ "$VKPR_ENV_JAEGER_PERSISTANCE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .cassandra.persistence.enabled = true |
      .cassandra.persistence.size = \"5Gi\"
    "
  fi

  if [[ "$VKPR_ENV_JAEGER_SSL" == "true" ]]; then
    if [[ "$VKPR_ENV_JAEGER_SSL_SECRET" == "" ]]; then
      VKPR_ENV_JAEGER_SSL_SECRET="jaeger-certificate"
      createSslSecret "$VKPR_ENV_JAEGER_SSL_SECRET" "$VKPR_ENV_JAEGER_NAMESPACE" "$VKPR_ENV_JAEGER_SSL_CERTIFICATE" "$VKPR_ENV_JAEGER_SSL_KEY"
    fi
    YQ_VALUES="$YQ_VALUES |
      .allInOne.ingress.tls[0].hosts[0] = \"$VKPR_ENV_JAEGER_DOMAIN\" |
      .allInOne.ingress.tls[0].secretName = \"$VKPR_ENV_JAEGER_NAMESPACE/$VKPR_ENV_JAEGER_SSL_SECRET\"
     "
  fi

  settingJaegerEnvironment

  debug "YQ_CONTENT = $YQ_VALUES"
}

settingJaegerEnvironment() {
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    YQ_VALUES="$YQ_VALUES"
  fi
}
