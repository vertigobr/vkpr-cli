#!/usr/bin/env bash

settingAlertManagerValues() {
  YQ_VALUES="$YQ_VALUES |
    .alertmanager.enabled = true |
    .alertmanager.ingress.enabled = true |
    .alertmanager.ingress.hosts[0] = \"$VKPR_ENV_ALERT_MANAGER_DOMAIN\" |
    .alertmanager.ingress.ingressClassName = \"$VKPR_ENV_PROMETHEUS_STACK_INGRESS_CLASS_NAME\"
  "

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .alertmanager.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .alertmanager.ingress.tls[0].hosts[0] = \"$VKPR_ENV_ALERT_MANAGER_DOMAIN\" |
      .alertmanager.ingress.tls[0].secretName = \"alertmanager-cert\"
    "
  fi

  if [[ "$VKPR_ENV_ALERTMANAGER_PERSISTENCE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage =\"$VKPR_ENV_ALERTMANAGER_VOLUME_SIZE\" 
    "
  fi

  if [[ "$VKPR_ENV_ALERTMANAGER_SSL" == "true" ]]; then
    if [[ "$VKPR_ENV_ALERTMANAGER_SSL_SECRET" == "" ]]; then
      VKPR_ENV_ALERTMANAGER_SSL_SECRET="alertmanager-certificate"
      createSslSecret "$VKPR_ENV_ALERTMANAGER_SSL_SECRET" "$VKPR_ENV_PROMETHEUS_STACK_NAMESPACE" "$VKPR_ENV_ALERTMANAGER_SSL_CERTIFICATE" "$VKPR_ENV_ALERTMANAGER_SSL_KEY"
    fi
    YQ_VALUES="$YQ_VALUES |
      .alertmanager.ingress.tls[0].hosts[0] = \"$VKPR_ENV_ALERT_MANAGER_DOMAIN\" |
      .alertmanager.ingress.tls[0].secretName = \"$VKPR_ENV_ALERTMANAGER_SSL_SECRET\"
     "
  fi

}