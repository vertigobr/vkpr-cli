#!/usr/bin/env bash

runFormula() {
  VKPR_ARGOCD_EVENTS_VALUES="$(dirname "$0")"/utils/argocd-events.yaml

  startInfos
  settingAddon
  installApplication "argo-events" "argo/argo-events" "argo-events" "$VKPR_ARGOCD_EVENTS_VERSION" "$VKPR_ARGOCD_EVENTS_VALUES" "$HELM_ARGS"
}

startInfos() {
  bold "=============================="
  boldInfo "Configuring ArgoCD Events Addon"
  bold "=============================="
}

settingAddon() {
  YQ_VALUES=""

  mergeVkprValuesHelmArgs "argocd.addons.events" "$VKPR_ARGOCD_EVENTS_VALUES"
}

runFormula
