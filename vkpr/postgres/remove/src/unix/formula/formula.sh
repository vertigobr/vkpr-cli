#!/bin/sh

runFormula() {
  removePostgres
  removePVC
}

removePostgres(){
  echoColor "green" "Removing Postgres..."
  $VKPR_HELM uninstall vkpr-postgres
}

removePVC(){
  echoColor "green" "Removing PVC..."
  $VKPR_KUBECTL delete pvc -l app.kubernetes.io/instance=vkpr-postgres
}