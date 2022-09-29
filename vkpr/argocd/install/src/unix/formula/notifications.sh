#!/usr/bin/env bash

runFormula() {
  startInfos
  settingAddon
}

startInfos() {
  bold "=============================="
  boldInfo "Configuring ArgoCD Notifications Addon"
  bold "=============================="
}

settingAddon() {
  ARGOCD_ADDRESS="argocd.${VKPR_ENV_GLOBAL_DOMAIN}"
  [[ $VKPR_ENV_GLOBAL_DOMAIN == "localhost" ]] && ARGOCD_ADDRESS="argocd.localhost:8000"

  ARGOCD_SSL="http"
  [[ $VKPR_ENV_GLOBAL_SECURE == "true" ]] && ARGOCD_SSL="https"

  YQ_VALUES="$YQ_VALUES |
    .notifications.enabled = true |
    .notifications.argocdUrl =  \"$ARGOCD_SSL://$ARGOCD_ADDRESS\"
  "
}

runFormula
