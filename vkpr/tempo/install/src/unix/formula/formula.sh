#!/usr/bin/env bash

runFormula() {
  local VKPR_TEMPO_VALUES HELM_ARGS;
  formulaInputs
  validateInputs
  
  VKPR_ENV_TEMPO_DOMAIN="tempo.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_TEMPO_DATASOURCE=$(dirname "$0")/utils/datasource.json
  VKPR_TEMPO_VALUES=$(dirname "$0")/utils/tempo.yaml

  startInfos
  settingTempo
  [ $DRY_RUN = false ] && [ $DIFF = false ] && registerHelmRepository tempo https://grafana.github.io/helm-charts
  installApplication "tempo" "grafana/tempo" "$VKPR_ENV_TEMPO_NAMESPACE" "$VKPR_TEMPO_VERSION" "$VKPR_TEMPO_VALUES" "$HELM_ARGS"
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Tempo Install Routine"
  bold "=============================="
}

## Add here values that can be used by the globals (env, vkpr values, input...)
formulaInputs() {
  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "tempo.ingressClassName" "TEMPO_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "tempo.namespace" "TEMPO_NAMESPACE"
  checkGlobalConfig "false" "false" "tempo.persistence" "TEMPO_PERSISTENCE"
  checkGlobalConfig "false" "false" "tempo.metrics" "TEMPO_METRICS"
  checkGlobalConfig "$SSL" "false" "tempo.ssl.enabled" "TEMPO_SSL"
  checkGlobalConfig "$CRT_FILE" "" "tempo.ssl.crt" "TEMPO_SSL_CERTIFICATE"
  checkGlobalConfig "$KEY_FILE" "" "tempo.ssl.key" "TEMPO_SSL_KEY"
  checkGlobalConfig "" "" "tempo.ssl.secretName" "TEMPO_SSL_SECRET"
  # External apps values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "GRAFANA_NAMESPACE"
}

## Add here the validators from the inputs
validateInputs() {
  validateTempoDomain "$VKPR_ENV_GLOBAL_DOMAIN"
  validateTempoSecure "$VKPR_ENV_GLOBAL_SECURE"
  validateTempoMetrics "$VKPR_ENV_TEMPO_METRICS"
  validateTempoIngressClassName "$VKPR_ENV_TEMPO_INGRESS_CLASS_NAME"
  validateTempoNamespace "$VKPR_ENV_TEMPO_NAMESPACE"
  validateTempoPersistance "$VKPR_ENV_TEMPO_PERSISTENCE"

  validateTempoSsl "$VKPR_ENV_TEMPO_SSL"
  if [[ $VKPR_ENV_TEMPO_SSL == true ]]; then
    validateTempoSslCrtPath "$VKPR_ENV_TEMPO_SSL_CERTIFICATE"
    validateTempoSslKeyPath "$VKPR_ENV_TEMPO_SSL_KEY"
  fi
}

# Add here a configuration of application
settingTempo() {
  YQ_VALUES=" .tempoQuery.ingress.hosts[0] = \"$VKPR_ENV_TEMPO_DOMAIN\" |
              .tempoQuery.ingress.ingressClassName = \"$VKPR_ENV_TEMPO_INGRESS_CLASS_NAME\" | 
              .tempoQuery.enabled = true "

  if [[ "$VKPR_ENV_TEMPO_METRICS" == true ]] && [[ $(checkPodName "$VKPR_ENV_GRAFANA_NAMESPACE" "prometheus-stack-grafana") == "true" ]]; then 
    DATASOURCE_URL="http://tempo.$VKPR_ENV_TEMPO_NAMESPACE:3100/"
    $VKPR_JQ ".url = \"$DATASOURCE_URL\"" $VKPR_TEMPO_DATASOURCE > tmp.json 
    cat tmp.json > $VKPR_TEMPO_DATASOURCE && rm tmp.json
    createGrafanaDatasource "$VKPR_TEMPO_DATASOURCE" "$VKPR_ENV_GRAFANA_NAMESPACE"

    # createGrafanaDashboard "$(dirname "$0")/utils/dashboard.json" "$VKPR_ENV_GRAFANA_NAMESPACE"
    YQ_VALUES="$YQ_VALUES |
      .serviceMonitor.enabled = true |
      .serviceMonitor.additionalLabels.release = \"prometheus-stack\"
    "
  fi
  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
  YQ_VALUES="$YQ_VALUES |
    .tempoQuery.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
    .tempoQuery.ingress.tls[0].hosts[0] = \"$VKPR_ENV_TEMPO_DOMAIN\" |
    .tempoQuery.ingress.tls[0].secretName = \"tempo-cert\"
  "
  fi

  # if [[ "$VKPR_ENV_TEMPO_PERSISTENCE" == true ]]; then
  #   YQ_VALUES="$YQ_VALUES |
  #     .persistence.enabled = true |
  #     .persistence.size = \"5Gi\"
  #   "
  # fi

  if [[ "$VKPR_ENV_TEMPO_SSL" == "true" ]]; then
    if [[ "$VKPR_ENV_TEMPO_SSL_SECRET" == "" ]]; then
      VKPR_ENV_TEMPO_SSL_SECRET="jaeger-certificate"
      createSslSecret "$VKPR_ENV_TEMPO_SSL_SECRET" "$VKPR_ENV_TEMPO_NAMESPACE" "$VKPR_ENV_TEMPO_SSL_CERTIFICATE" "$VKPR_ENV_TEMPO_SSL_KEY"
    fi
    YQ_VALUES="$YQ_VALUES |
      .tempoQuery.ingress.tls[0].hosts[0] = \"$VKPR_ENV_TEMPO_DOMAIN\" |
      .tempoQuery.ingress.tls[0].secretName = \"$VKPR_ENV_TEMPO_NAMESPACE/$VKPR_ENV_TEMPO_SSL_SECRET\"
     "
  fi
  settingTempoEnvironment

  debug "YQ_CONTENT = $YQ_VALUES"
}

# Add here a configuration of application in specific envs
settingTempoEnvironment() {
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    YQ_VALUES="$YQ_VALUES"
  fi
}
