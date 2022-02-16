#!/bin/sh

runFormula() {
  removePostgres
  removePVC
}

removePostgres(){
  echoColor "bold" "$(echoColor "green" "Removing Postgresql...")"

  POSTGRESQL_NAMESPACE=$($VKPR_KUBECTL get po -A -l app.kubernetes.io/instance=postgresql,vkpr=true -o=yaml | $VKPR_YQ e ".items[].metadata.namespace" - | head -n1)
  $VKPR_HELM uninstall --namespace $POSTGRESQL_NAMESPACE postgresql
}

removePVC(){
  echoColor "bold" "$(echoColor "green" "Removing PVC...")"
  $VKPR_KUBECTL delete pvc -A -l app.kubernetes.io/instance=postgresql
}
