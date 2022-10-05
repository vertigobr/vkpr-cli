#!/usr/bin/env bash

runFormula() {
  VKPR_ARGOCD_ROLLOUTS_VALUES="$(dirname "$0")"/utils/argocd-rollouts.yaml

  startInfos
  settingAddon
  installApplication "argo-rollouts" "argo/argo-rollouts" "$VKPR_ENV_ARGOCD_NAMESPACE" "$VKPR_ARGOCD_ROLLOUTS_VERSION" "$VKPR_ARGOCD_ROLLOUTS_VALUES" "$HELM_ARGS"
}

startInfos() {
  bold "=============================="
  boldInfo "Configuring ArgoCD Rollouts Addon"
  bold "=============================="
}

settingAddon() {
  YQ_VALUES=".dashboard.ingress.hosts[0] = \"rollout.argocd.$VKPR_ENV_GLOBAL_DOMAIN\" |
    .dashboard.ingress.ingressClassName = \"$VKPR_ENV_ARGOCD_INGRESS_CLASS_NAME\"
  "

  mergeVkprValuesHelmArgs "argocd.addons.rollouts" "$VKPR_ARGOCD_ROLLOUTS_VALUES"
}

runFormula
