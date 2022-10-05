#!/usr/bin/env bash

runFormula() {
  VKPR_ARGOCD_WORKFLOWS_VALUES="$(dirname "$0")"/utils/argocd-workflows.yaml

  startInfos
  settingAddon
  installApplication "argo-workflows" "argo/argo-workflows" "argo-workflow" "$VKPR_ARGOCD_WORKFLOWS_VERSION" "$VKPR_ARGOCD_WORKFLOWS_VALUES" "$HELM_ARGS"
}

startInfos() {
  bold "=============================="
  boldInfo "Configuring ArgoCD Workflows Addon"
  bold "=============================="
}

settingAddon() {
  YQ_VALUES=".server.ingress.hosts[0] = \"workflows.argocd.localhost\" |
    .server.ingress.ingressClassName = \"$VKPR_ENV_ARGOCD_INGRESS_CLASS_NAME\"
  "

  mergeVkprValuesHelmArgs "argocd.addons.workflows" "$VKPR_ARGOCD_WORKFLOWS_VALUES"
}

runFormula
