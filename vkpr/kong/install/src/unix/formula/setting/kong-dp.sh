#!/usr/bin/env bash
source "$(dirname "$0")"/unix/formula/objects.sh

settingKong() {
  YQ_VALUES=".podLabels.[\"app.kubernetes.io/managed-by\"] = \"vkpr\""

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    info "Creating proxy certificate..."
    $VKPR_YQ eval ".spec.dnsNames[0] = \"$VKPR_ENV_GLOBAL_DOMAIN\"" "$(dirname "$0")"/utils/proxy-certificate.yaml |\
      $VKPR_KUBECTL apply -n $VKPR_ENV_KONG_NAMESPACE -f -
    YQ_VALUES="$YQ_VALUES |
      .secretVolumes[0] = \"proxy-kong-cert\" |
      .env.ssl_cert = \"/etc/secrets/proxy-kong-cert/tls.crt\" |
      .env.ssl_cert_key = \"/etc/secrets/proxy-kong-cert/tls.key\" |
      .env.proxy_url = \"https://$VKPR_ENV_GLOBAL_DOMAIN\" |
      .proxy.annotations.[\"external-dns.alpha.kubernetes.io/hostname\"] = \"$VKPR_ENV_GLOBAL_DOMAIN\"
    "
  fi

  if [[ "$VKPR_ENV_KONG_METRICS" == "true" ]]; then
    createGrafanaDashboard "$(dirname "$0")/utils/dashboard.json" "$VKPR_ENV_GRAFANA_NAMESPACE"
    $VKPR_KUBECTL apply -f "$(dirname "$0")/utils/alerts.yaml" -n "$VKPR_ENV_GRAFANA_NAMESPACE"
    YQ_VALUES="$YQ_VALUES |
      .serviceMonitor.enabled = \"true\" |
      .serviceMonitor.namespace = \"$VKPR_ENV_KONG_NAMESPACE\" |
      .serviceMonitor.interval = \"30s\" |
      .serviceMonitor.scrapeTimeout = \"30s\" |
      .serviceMonitor.labels.release = \"prometheus-stack\" |
      .serviceMonitor.targetLabels[0] = \"prometheus-stack\"
    "
    if [[ "$VKPR_ENV_KONG_VITALS_STRATEGY" == "true" ]]; then
      YQ_VALUES="$YQ_VALUES |
        .env.vitals = \"on\" |
        .env.vitals_strategy = \"prometheus\" |
        .env.vitals_statsd_address = \"statsd-kong:9125\" |
        .env.vitals_tsdb_address = \"prometheus-stack-kube-prom-prometheus:9090\" |
        .env.vitals_statsd_prefix = \"kong-vitals\"
      "
      $VKPR_KUBECTL apply $KONG_NAMESPACE -f "$(dirname "$0")/utils/kong-service-monitor.yaml"
    fi
  fi

  if [[ "$VKPR_ENV_KONG_HA" == "true" ]]; then
    YQ_VALUES="$YQ_VALUES |
      .autoscaling.enabled = \"true\" |
      .autoscaling.minReplicas = \"3\" |
      .autoscaling.maxReplicas = \"5\" |
      .autoscaling.targetCPUUtilizationPercentage = \"80%\" |
      .topologySpreadConstraints[0].maxSkew = 1 |
      .topologySpreadConstraints[0].topologyKey = \"kubernetes.io/hostname\" |
      .topologySpreadConstraints[0].whenUnsatisfiable = \"DoNotSchedule\" |
      .topologySpreadConstraints[0].labelSelector.matchLabels.vkpr = \"true\" |
      .podDisruptionBudget.enabled = \"true\" |
      .podDisruptionBudget.maxUnavailable = \"60%\" |
      .resources.limits.cpu = \"512m\" |
      .resources.limits.memory = \"1G\" |
      .resources.requests.cpu = \"100m\" |
      .resources.requests.memory = \"128Mi\"
    "
  fi

  settingKongProvider

  debug "YQ_CONTENT = $YQ_VALUES"
}

settingKongProvider(){
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    OKTETO_NAMESPACE=$($VKPR_KUBECTL config get-contexts --no-headers | grep "\*" | xargs | awk -F " " '{print $NF}')
    HELM_ARGS="--skip-crds"
    YQ_VALUES="$YQ_VALUES |
        .proxy.tls.enabled = false |
        .proxy.annotations.[\"dev.okteto.com/auto-ingress\"] = \"true\" |
        .proxy.type = \"ClusterIP\" |
        .env.proxy_url = \"https://kong-kong-proxy-$OKTETO_NAMESPACE.cloud.okteto.net\"
      "
  fi
}

[[ $DIFF == false ]] && createSecretsKongDp
settingKong
