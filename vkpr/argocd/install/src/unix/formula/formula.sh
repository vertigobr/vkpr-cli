#!/usr/bin/env bash
source "$(dirname "$0")"/unix/formula/commands-operators.sh

runFormula() {
  local VKPR_ENV_ARGOCD_DOMAIN VKPR_ARGOCD_VALUES HELM_ARGS;
  formulaInputs
  validateInputs

  VKPR_ENV_ARGOCD_DOMAIN="argocd.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_ARGOCD_VALUES="$(dirname "$0")"/utils/argocd.yaml

  startInfos
  settingArgoCD
  [ $DRY_RUN = false ] && registerHelmRepository argo https://argoproj.github.io/argo-helm
  installApplication "argocd" "argo/argo-cd" "$VKPR_ENV_ARGOCD_NAMESPACE" "$VKPR_ARGOCD_VERSION" "$VKPR_ARGOCD_VALUES" "$HELM_ARGS"
  if [ $DRY_RUN = false ]; then
   # printArgoPassword
    checkComands
  fi
  settingArgoAddons
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR ArgoCD Install Routine"
  boldNotice "Domain: $VKPR_ENV_ARGOCD_DOMAIN"
  boldNotice "Secure: $VKPR_ENV_GLOBAL_SECURE"
  boldNotice "Namespace: $VKPR_ENV_ARGOCD_NAMESPACE"
  boldNotice "HA: $VKPR_ENV_ARGOCD_HA"
  boldNotice "Ingress Controller: $VKPR_ENV_ARGOCD_INGRESS_CLASS_NAME"
  bold "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "$HA" "false" "argocd.HA" "ARGOCD_HA"
  checkGlobalConfig "argocd" "argocd" "argocd.namespace" "ARGOCD_NAMESPACE"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "argocd.ingressClassName" "ARGOCD_INGRESS_CLASS_NAME"
  checkGlobalConfig "false" "false" "argocd.metrics" "ARGOCD_METRICS"
  checkGlobalConfig "$SSL" "false" "argocd.ssl.enabled" "ARGOCD_SSL"
  checkGlobalConfig "$CRT_FILE" "" "argocd.ssl.crt" "ARGOCD_SSL_CERTIFICATE"
  checkGlobalConfig "$KEY_FILE" "" "argocd.ssl.key" "ARGOCD_SSL_KEY"
  checkGlobalConfig "" "" "argocd.ssl.secretName" "ARGOCD_SSL_SECRET"

  # Addons Values
  checkGlobalConfig "false" "false" "argocd.addons.notifications.enabled" "ARGOCD_ADDONS_NOTIFICATIONS"
  checkGlobalConfig "false" "false" "argocd.addons.rollouts.enabled" "ARGOCD_ADDONS_ROLLOUTS"
  checkGlobalConfig "false" "false" "argocd.addons.events.enabled" "ARGOCD_ADDONS_EVENTS"
  checkGlobalConfig "false" "false" "argocd.addons.workflows.enabled" "ARGOCD_ADDONS_WORKFLOWS"


  # External apps values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "GRAFANA_NAMESPACE"
}

validateInputs() {
  validateArgoDomain "$VKPR_ENV_GLOBAL_DOMAIN"
  validateArgoSecure "$VKPR_ENV_GLOBAL_SECURE"
  validateArgoHa "$VKPR_ENV_ARGOCD_HA"
  validateArgoNamespace "$VKPR_ENV_ARGOCD_NAMESPACE"
  validateArgoSsl "$VKPR_ENV_ARGOCD_SSL"
  if [[ "$VKPR_ENV_ARGOCD_SSL" == true  ]] ; then
    validateArgoSslCrt "$VKPR_ENV_ARGOCD_SSL_CERTIFICATE"
    validateArgoSslKey "$VKPR_ENV_ARGOCD_SSL_KEY"
  fi
  validateArgoIngressClassName "$VKPR_ENV_ARGOCD_INGRESS_CLASS_NAME"
  validateArgoMetrics "$VKPR_ENV_ARGOCD_METRICS"
}

settingArgoCD() {
  YQ_VALUES=".server.ingress.hosts[0] = \"$VKPR_ENV_ARGOCD_DOMAIN\" |
    .server.config.url = \"$VKPR_ENV_ARGOCD_DOMAIN\" |
    .server.ingress.annotations.[\"kubernetes.io/ingress.class\"] = \"$VKPR_ENV_ARGOCD_INGRESS_CLASS_NAME\"
  "

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .server.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .server.ingress.tls[0].secretName = \"argocd-cert\" |
      .server.ingress.tls[0].hosts[0] = \"$VKPR_ENV_ARGOCD_DOMAIN\" |
      .server.ingress.https = true
    "
  fi

  if [[ "$VKPR_ENV_ARGOCD_HA" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .controller.enableStatefulSet = true |
      .redis.enabled = true |
      .redis-ha.enabled = true |
      .redis-ha.exporter.enabled = false |
      .repoServer.replicas = 2 |
      .server.env[0].name = \"ARGOCD_API_SERVER_REPLICAS\" |
      .server.env[0].value = \"3\" |
      .server.replicas = 3
    "
  fi

  if [[ "$VKPR_ENV_ARGOCD_METRICS" == true ]] && [[ $(checkPodName "$VKPR_ENV_GRAFANA_NAMESPACE" "prometheus-stack-grafana") == "true" ]]; then
    createGrafanaDashboard "$(dirname "$0")/utils/dashboard.json" "$VKPR_ENV_GRAFANA_NAMESPACE"
    YQ_VALUES="$YQ_VALUES |
      .controller.metrics.enabled = true |
      .controller.metrics.serviceMonitor.enabled = true |
      .controller.metrics.serviceMonitor.namespace = \"$VKPR_ENV_ARGOCD_NAMESPACE\" |
      .controller.metrics.serviceMonitor.interval = \"30s\" |
      .controller.metrics.serviceMonitor.scrapeTimeout = \"30s\" |
      .controller.metrics.serviceMonitor.additionalLabels.release = \"prometheus-stack\" |
      .server.metrics.enabled = true |
      .server.metrics.serviceMonitor.enabled = true |
      .server.metrics.serviceMonitor.namespace = \"$VKPR_ENV_ARGOCD_NAMESPACE\" |
      .server.metrics.serviceMonitor.interval = \"30s\" |
      .server.metrics.serviceMonitor.scrapeTimeout = \"30s\" |
      .server.metrics.serviceMonitor.additionalLabels.release = \"prometheus-stack\"
    "
  fi

  if [[ "$VKPR_ENV_ARGOCD_SSL" == "true" ]]; then
    if [[ "$VKPR_ENV_ARGOCD_SSL_SECRET" == "" ]]; then
      VKPR_ENV_ARGOCD_SSL_SECRET="argocd-certificate"
      $VKPR_KUBECTL create secret tls $VKPR_ENV_ARGOCD_SSL_SECRET -n "$VKPR_ENV_ARGOCD_NAMESPACE" \
        --cert="$VKPR_ENV_ARGOCD_SSL_CERTIFICATE" \
        --key="$VKPR_ENV_ARGOCD_SSL_KEY"
    fi
    YQ_VALUES="$YQ_VALUES |
      .server.ingress.tls[0].hosts[0] = \"$VKPR_ENV_ARGOCD_DOMAIN\" |
      .server.ingress.tls[0].secretName = \"$VKPR_ENV_ARGOCD_SSL_SECRET\"
     "
  fi

  [ "$VKPR_ENV_ARGOCD_ADDONS_NOTIFICATIONS" == true ] && source $(dirname "$0")/unix/formula/notifications.sh

  debug "YQ_CONTENT = $YQ_VALUES"
}

printArgoPassword(){
  PASSWORD=$($VKPR_KUBECTL -n "$VKPR_ENV_ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
  notice "Your ArgoCD Super Admin password is ${PASSWORD}, we recommend that it be changed after the first login"
}

settingArgoAddons(){
  ADDONS_EXISTS=$($VKPR_YQ eval ".argocd | has(\"addons\")" "$VKPR_FILE")
  if [ "$ADDONS_EXISTS" == true ]; then
    [ "$VKPR_ENV_ARGOCD_ADDONS_ROLLOUTS" == true ] && source $(dirname "$0")/unix/formula/rollouts.sh
    [ "$VKPR_ENV_ARGOCD_ADDONS_EVENTS" == true ] && source $(dirname "$0")/unix/formula/events.sh
    [ "$VKPR_ENV_ARGOCD_ADDONS_WORKFLOWS" == true ] && source $(dirname "$0")/unix/formula/workflows.sh
  fi
}

checkComands (){
  COMANDS_EXISTS=$($VKPR_YQ eval ".argocd | has(\"commands\")" "$VKPR_FILE")
  debug $COMANDS_EXISTS
  if [ "$COMANDS_EXISTS" == true ]; then
    boldInfo "Checking additional argocd commands..."
    if [ $($VKPR_YQ eval ".argocd.commands | has(\"repository\")" "$VKPR_FILE") == true ]; then
      checkGlobalConfig "" "" "argocd.commands.repository.repo_url" "ARGOCD_COMANDS_REPOSITORY_URL"
      GITLAB_USERNAME="$($VKPR_JQ -r '.credentials.gitlab.username' $VKPR_CREDENTIAL/gitlab)"
      GITLAB_TOKEN="$($VKPR_JQ -r '.credentials.gitlab.token' $VKPR_CREDENTIAL/gitlab)"
      argocdSetRepo "$VKPR_ENV_ARGOCD_COMANDS_REPOSITORY_URL" "$VKPR_ENV_ARGOCD_NAMESPACE" "$GITLAB_USERNAME" "$GITLAB_TOKEN"
    fi

    if [ $($VKPR_YQ eval ".argocd.commands | has(\"aplicationset\")" "$VKPR_FILE") == true ]; then
      checkGlobalConfig "" "" "argocd.commands.aplicationset.repo_url" "ARGOCD_COMANDS_REPOSITORY_URL"
      argocdAplicationSet "$VKPR_ENV_ARGOCD_COMANDS_REPOSITORY_URL" "$VKPR_ENV_ARGOCD_NAMESPACE" "$(dirname "$0")"/utils/applicationset.yaml
    fi
  fi
}
