#!/usr/bin/env bash

runFormula() {
  bold "$(info "Removing cert-manager...")"

  HELM_FLAG="-A"
  [[ "$VKPR_ENVIRONMENT" == "okteto" ]] && HELM_FLAG=""
  CERT_MANAGER_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG |\
                     $VKPR_JQ -r '.[] | select(.name | contains("cert-manager")) | .namespace' |\
                     head -n1)

  $VKPR_KUBECTL get crd | grep -q clusterissuer && uninstallResources
  uninstallCertManager
}

uninstallCertManager() {
  $VKPR_HELM uninstall cert-manager -n "$CERT_MANAGER_NAMESPACE" 2> /dev/null || error "VKPR Cert-manager not found"
  $VKPR_KUBECTL delete secret $HELM_FLAG -l app.kubernetes.io/instance=cert-manager,app.kubernetes.io/managed-by=vkpr > /dev/null
}

uninstallResources() {
  $VKPR_KUBECTL delete ClusterIssuer $HELM_FLAG -l app.kubernetes.io/managed-by=vkpr > /dev/null
}
