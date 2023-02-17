#!/usr/bin/env bash

settingPrometheusValues() {
  YQ_VALUES="$YQ_VALUES |
    .prometheus.enabled = true |
    .prometheus.ingress.enabled = true |
    .prometheus.ingress.hosts[0] = \"$VKPR_ENV_PROMETHEUS_DOMAIN\" |
    .prometheus.ingress.ingressClassName = \"$VKPR_ENV_PROMETHEUS_STACK_INGRESS_CLASS_NAME\"
  "

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .prometheus.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .prometheus.ingress.tls[0].hosts[0] = \"$VKPR_ENV_PROMETHEUS_DOMAIN\" |
      .prometheus.ingress.tls[0].secretName = \"prometheus-cert\"
    "
  fi

  if [[ "$VKPR_ENV_PROMETHEUS_SSL" == "true" ]]; then
    if [[ "$VKPR_ENV_PROMETHEUS_SSL_SECRET" == "" ]]; then
      VKPR_ENV_PROMETHEUS_SSL_SECRET="prometheus-certificate"
      createSslSecret "$VKPR_ENV_PROMETHEUS_SSL_SECRET" "$VKPR_ENV_PROMETHEUS_STACK_NAMESPACE" "$VKPR_ENV_PROMETHEUS_SSL_CERTIFICATE" "$VKPR_ENV_PROMETHEUS_SSL_KEY"
    fi
    YQ_VALUES="$YQ_VALUES |
      .prometheus.ingress.tls[0].hosts[0] = \"$VKPR_ENV_PROMETHEUS_DOMAIN\" |
      .prometheus.ingress.tls[0].secretName = \"$VKPR_ENV_PROMETHEUS_SSL_SECRET\"
     "
  fi

  if [[ "$VKPR_ENV_PROMETHEUS_PERSISTENCE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0] = \"ReadWriteOnce\" |
      .prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage = \"$VKPR_ENV_PROMETHEUS_VOLUME_SIZE\"
    "
  fi
}