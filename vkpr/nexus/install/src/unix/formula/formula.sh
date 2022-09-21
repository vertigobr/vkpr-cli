#!/usr/bin/env bash

runFormula() {
  local VKPR_NEXUS_VALUES HELM_ARGS;
  formulaInputs
  validateInputs

  VKPR_ENV_NEXUS_DOMAIN="nexus.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_ENV_DOCKER_REGISTRY_DOMAIN="registry.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_NEXUS_VALUES=$(dirname "$0")/utils/nexus.yaml

  startInfos
  settingNexus
  [ $DRY_RUN = false ] && registerHelmRepository stevehipwell https://stevehipwell.github.io/helm-charts/
  installApplication "nexus" "stevehipwell/nexus3" "$VKPR_ENV_NEXUS_NAMESPACE" "$VKPR_NEXUS_VERSION" "$VKPR_NEXUS_VALUES" "$HELM_ARGS"
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Nexus Install Routine"
  boldNotice "Domain: $VKPR_ENV_NEXUS_DOMAIN"
  boldNotice "Secure: $VKPR_ENV_GLOBAL_SECURE"
  boldNotice "Namespace: $VKPR_ENV_NEXUS_NAMESPACE"
  boldNotice "Ingress Controller: $VKPR_ENV_NEXUS_INGRESS_CLASS_NAME"
  boldNotice "Domain Docker Registry: $VKPR_ENV_DOCKER_REGISTRY_DOMAIN"
  bold "=============================="
}

formulaInputs() {
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "nexus.namespace" "NEXUS_NAMESPACE"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "nexus.ingressClassName" "NEXUS_INGRESS_CLASS_NAME"

  checkGlobalConfig "$PASSWORD" "vkpr123" "nexus.rootPassword" "NEXUS_ROOT_PASSWORD"
  checkGlobalConfig "false" "false" "nexus.persistence" "NEXUS_PERSISTENCE"
  checkGlobalConfig "false" "false" "nexus.metrics" "NEXUS_METRICS"
  checkGlobalConfig "$SSL" "false" "nexus.ssl.enabled" "NEXUS_SSL"
  checkGlobalConfig "$CRT_FILE" "" "nexus.ssl.crt" "NEXUS_SSL_CERTIFICATE"
  checkGlobalConfig "$KEY_FILE" "" "nexus.ssl.key" "NEXUS_SSL_KEY"
  checkGlobalConfig "" "" "nexus.ssl.secretName" "NEXUS_SSL_SECRET"

  # External apps values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "GRAFANA_NAMESPACE"
}

validateInputs() {
  validateNexusDomain "$VKPR_ENV_GLOBAL_DOMAIN"
  validateNexusSecure "$VKPR_ENV_GLOBAL_SECURE"
  validateNexusNamespace "$VKPR_ENV_NEXUS_NAMESPACE"
  validateNexusIngressClassName "$VKPR_ENV_NEXUS_INGRESS_CLASS_NAME"

  validateNexusPwd "$VKPR_ENV_NEXUS_ROOT_PASSWORD"
  validateNexusMetrics "$VKPR_ENV_NEXUS_METRICS"
  validateNexusPersistance "$VKPR_ENV_NEXUS_PERSISTENCE"

  validateNexusSsl "$VKPR_ENV_NEXUS_SSL"
  if [[ $VKPR_ENV_NEXUS_SSL == true ]]; then
    validateNexusSslCrtPath "$VKPR_ENV_NEXUS_SSL_CERTIFICATE"
    validateNexusSslKeyPath "$VKPR_ENV_NEXUS_SSL_KEY"
  fi
}

settingNexus() {
  YQ_VALUES=".ingress.hosts[0] = \"$VKPR_ENV_NEXUS_DOMAIN\" |
    .service.additionalPorts[0].host = \"$VKPR_ENV_DOCKER_REGISTRY_DOMAIN\" |
    .ingress.ingressClassName = \"$VKPR_ENV_NEXUS_INGRESS_CLASS_NAME\"
  "

  $VKPR_KUBECTL create secret generic nexus-password -n $VKPR_ENV_NEXUS_NAMESPACE --from-literal="rootPassword=$VKPR_ENV_NEXUS_ROOT_PASSWORD"

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .ingress.tls[0].hosts[0] = \"$VKPR_ENV_NEXUS_DOMAIN\" |
      .ingress.tls[0].secretName = \"nexus-cert\"
    "
  fi

  if [[ "$VKPR_ENV_NEXUS_METRICS" == true ]] && [[ $(checkPodName "$VKPR_ENV_GRAFANA_NAMESPACE" "prometheus-stack-grafana") == "true" ]]; then
    YQ_VALUES="$YQ_VALUES |
      .metrics.enabled= true |
      .metrics.serviceMonitor.enabled= true |
      .metrics.serviceMonitor.additionalLabels.release = \"prometheus-stack\"
    "
  fi

  if [[ "$VKPR_ENV_NEXUS_PERSISTANCE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .persistence.enabled = true |
      .persistence.size = \"5Gi\"
    "
  fi

  if [[ "$VKPR_ENV_NEXUS_SSL" == "true" ]]; then
    if [[ "$VKPR_ENV_NEXUS_SSL_SECRET" == "" ]]; then
      VKPR_ENV_NEXUS_SSL_SECRET="nexus-certificate"
      $VKPR_KUBECTL create secret tls $VKPR_ENV_NEXUS_SSL_SECRET -n "$VKPR_ENV_NEXUS_NAMESPACE" \
        --cert="$VKPR_ENV_NEXUS_SSL_CERTIFICATE" \
        --key="$VKPR_ENV_NEXUS_SSL_KEY"
    fi
    YQ_VALUES="$YQ_VALUES |
      .ingress.tls[0].secretName = \"$VKPR_ENV_NEXUS_NAMESPACE/$VKPR_ENV_NEXUS_SSL_SECRET\"
     "
  fi

  settingNexusEnvironment

  debug "YQ_CONTENT = $YQ_VALUES"
}

settingNexusEnvironment() {
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    YQ_VALUES="$YQ_VALUES"
  fi
}
