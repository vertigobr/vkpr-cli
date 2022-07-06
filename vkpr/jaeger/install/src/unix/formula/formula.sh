#!/bin/bash

runFormula() {
  local VKPR_ENV_JAEGER_DOMAIN VKPR_JAEGER_VALUES HELM_ARGS;
  formulaInputs
  #validateInputs

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
  checkGlobalConfig "false" "false" "jaeger.persistence" "JAEGER_PERSISTANCE"
  checkGlobalConfig "$SSL" "false" "jaeger.ssl.enabled" "JAEGER_SSL"
  checkGlobalConfig "$CRT_FILE" "" "jaeger.ssl.crt" "JAEGER_CERTIFICATE"
  checkGlobalConfig "$KEY_FILE" "" "jaeger.ssl.key" "JAEGER_KEY"
  checkGlobalConfig "" "" "jaeger.ssl.secretName" "JAEGER_SSL_SECRET"
}

#validateInputs() {}

settingJaeger() {
  YQ_VALUES=".query.ingress.hosts[0] = \"$VKPR_ENV_JAEGER_DOMAIN\" |
    .query.ingress.ingressClassName = \"$VKPR_ENV_JAEGER_INGRESS_CLASS_NAME\"
  "

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .query.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .query.ingress.tls[0].hosts[0] = \"$VKPR_ENV_JAEGER_DOMAIN\" |
      .query.ingress.tls[0].secretName = \"jaeger-cert\"
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
      $VKPR_KUBECTL create secret tls $VKPR_ENV_JAEGER_SSL_SECRET -n "$VKPR_ENV_JAEGER_NAMESPACE" \
        --cert="$VKPR_ENV_JAEGER_CERTIFICATE" \
        --key="$VKPR_ENV_JAEGER_KEY"
    fi 
    YQ_VALUES="$YQ_VALUES |
      .query.ingress.tls[0].hosts[0] = \"$VKPR_ENV_JAEGER_DOMAIN\" |
      .query.ingress.tls[0].secretName = \"$VKPR_ENV_JAEGER_NAMESPACE/$VKPR_ENV_JAEGER_SSL_SECRET\"
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