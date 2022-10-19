#!/usr/bin/env bash

formulaInputs() {
  # App values
  checkGlobalConfig "$SSL" "false" "whoami.ssl.enabled" "WHOAMI_SSL"
  checkGlobalConfig "$CRT_FILE" "" "whoami.ssl.crt" "WHOAMI_SSL_CERTIFICATE"
  checkGlobalConfig "$KEY_FILE" "" "whoami.ssl.key" "WHOAMI_SSL_KEY"
  checkGlobalConfig "" "" "whoami.ssl.secretName" "WHOAMI_SSL_SECRET"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "whoami.ingressClassName" "WHOAMI_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "whoami.namespace" "WHOAMI_NAMESPACE"
}

validateInputs() {
  validateWhoamiDomain "$VKPR_ENV_WHOAMI_DOMAIN"
  validateWhoamiSecure "$VKPR_ENV_GLOBAL_SECURE"
  validateWhoamiSsl "$VKPR_ENV_WHOAMI_SSL"
  if [[ "$VKPR_ENV_WHOAMI_SSL" == true  ]] ; then
    validateWhoamiSslCrtPath "$VKPR_ENV_WHOAMI_SSL_CERTIFICATE"
    validateWhoamiSslKeyPath "$VKPR_ENV_WHOAMI_SSL_KEY"
  fi
}
