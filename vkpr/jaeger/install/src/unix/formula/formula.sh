#!/bin/bash

runFormula() {
  # Global values
  checkGlobalConfig "$DOMAIN" "localhost" "global.domain" "GLOBAL_DOMAIN"
  checkGlobalConfig "$SECURE" "false" "global.secure" "GLOBAL_SECURE"
  checkGlobalConfig "nginx" "nginx" "global.ingressClassName" "GLOBAL_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "global.namespace" "GLOBAL_NAMESPACE"

  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "jaeger.ingressClassName" "JAEGER_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "jaeger.namespace" "JAEGER_NAMESPACE"
  checkGlobalConfig "false" "false" "jaeger.persistence" "JAEGER_PERSISTANCE"
  checkGlobalConfig "$SSL" "false" "jaeger.ssl.enabled" "JAEGER_SSL"
  checkGlobalConfig "$CRT_FILE" "" "jaeger.ssl.crt" "JAEGER_CERTIFICATE"
  checkGlobalConfig "$KEY_FILE" "" "jaeger.ssl.key" "JAEGER_KEY"
  checkGlobalConfig "" "" "jaeger.ssl.secretName" "JAEGER_SSL_SECRET"

  local VKPR_ENV_JAEGER_DOMAIN="jaeger.${VKPR_ENV_GLOBAL_DOMAIN}"
  local VKPR_JAEGER_VALUES; VKPR_JAEGER_VALUES=$(dirname "$0")/utils/jaeger.yaml

  startInfos
  addRepoJaeger
  installJaeger
}

startInfos() {
  echo "=============================="
  info "VKPR Jaeger Install Routine"
  notice "Jaeger Domain: $VKPR_ENV_JAEGER_DOMAIN"
  notice "Ingress Controller: $VKPR_ENV_JAEGER_INGRESS_CLASS_NAME"
  echo "=============================="
}

addRepoJaeger() {
  registerHelmRepository jaegertracing https://jaegertracing.github.io/helm-charts
}

installJaeger() {
  local YQ_VALUES=".query.ingress.hosts[0] = \"$VKPR_ENV_JAEGER_DOMAIN\""
  settingJaeger

  if [[ $DRY_RUN == true ]]; then
    echoColor "bold" "---"
    mergeVkprValuesHelmArgs "jaeger" "$VKPR_JAEGER_VALUES"
    $VKPR_YQ eval "$YQ_VALUES" "$VKPR_JAEGER_VALUES"
  else
    info "Installing Jaeger..."
    $VKPR_YQ eval -i "$YQ_VALUES" "$VKPR_JAEGER_VALUES"
    mergeVkprValuesHelmArgs "jaeger" "$VKPR_JAEGER_VALUES"
    $VKPR_HELM upgrade -i --version "$VKPR_JAEGER_VERSION" \
      --namespace "$VKPR_ENV_JAEGER_NAMESPACE" --create-namespace \
      --wait -f "$VKPR_JAEGER_VALUES" jaeger jaegertracing/jaeger
  fi
}

settingJaeger() {
  YQ_VALUES="$YQ_VALUES |
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
}