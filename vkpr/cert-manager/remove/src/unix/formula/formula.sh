#!/bin/bash

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing cert-manager...")"
  uninstallCertManager
  $VKPR_KUBECTL get crd | grep -q clusterissuer && uninstallResources
}

uninstallCertManager() {
  CERT_MANAGER_NAMESPACE=$($VKPR_KUBECTL get po -A -l app.kubernetes.io/instance=cert-manager,vkpr=true -o=yaml |\
                           $VKPR_YQ e ".items[].metadata.namespace" - |\
                           head -n1)
  $VKPR_HELM uninstall cert-manager -n "$CERT_MANAGER_NAMESPACE" 2> /dev/null || echoColor "red" "VKPR Cert-manager not found"
  $VKPR_KUBECTL delete secret -A -l app.kubernetes.io/instance=cert-manager,vkpr=true > /dev/null
}

uninstallResources() {
  $VKPR_KUBECTL delete ClusterIssuer -A -l vkpr=true > /dev/null
}