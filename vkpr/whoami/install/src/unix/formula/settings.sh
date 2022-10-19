#!/usr/bin/env bash

settingWhoami() {
  YQ_VALUES=".ingress.hosts[0].host = \"$VKPR_ENV_WHOAMI_DOMAIN\" |
    .ingress.ingressClassName = \"$VKPR_ENV_WHOAMI_INGRESS_CLASS_NAME\"
  "

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .ingress.tls[0].hosts[0] = \"$VKPR_ENV_WHOAMI_DOMAIN\" |
      .ingress.tls[0].secretName = \"whoami-cert\"
    "
  fi

  if [[ "$VKPR_ENV_WHOAMI_SSL" == "true" ]]; then
    [[ "$VKPR_ENV_WHOAMI_SSL_SECRET" == "" ]] && VKPR_ENV_WHOAMI_SSL_SECRET=$(createSecretTLS)
    YQ_VALUES="$YQ_VALUES |
      .ingress.tls[0].hosts[0] = \"$VKPR_ENV_WHOAMI_DOMAIN\" |
      .ingress.tls[0].secretName = \"$VKPR_ENV_WHOAMI_SSL_SECRET\"
     "
  fi

  settingWhoamiEnvironment

  debug "YQ_CONTENT = $YQ_VALUES"
}

settingWhoamiEnvironment() {
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    YQ_VALUES="$YQ_VALUES |
      .ingress.enabled = false |
      .service.annotations.[\"dev.okteto.com/auto-ingress\"] = \"true\"
    "
  fi
}
