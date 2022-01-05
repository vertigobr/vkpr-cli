#!/bin/sh

runFormula() {
  removePostgres
  removePVC
}

removePostgres(){
  echoColor "green" "Removing Postgres..."
  $VKPR_HELM uninstall --namespace $VKPR_K8S_NAMESPACE postgresql
}

removePVC(){
  echoColor "green" "Removing PVC..."
  $VKPR_KUBECTL delete pvc --namespace $VKPR_K8S_NAMESPACE -l app.kubernetes.io/instance=postgresql
  $VKPR_KUBECTL delete pvc --namespace $VKPR_K8S_NAMESPACE -l app=postgresql
}
