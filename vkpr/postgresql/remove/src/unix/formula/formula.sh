#!/bin/bash

runFormula() {
  removePostgres
  removePVC
}

removePostgres(){
  info "Removing Postgresql..."

  POSTGRESQL_NAMESPACE=$($VKPR_KUBECTL get po -A -l app.kubernetes.io/instance=postgresql,vkpr=true -o=yaml |\
                         $VKPR_YQ e ".items[].metadata.namespace" - |\
                         head -n1)

  $VKPR_HELM uninstall --namespace "$POSTGRESQL_NAMESPACE" postgresql 2> /dev/null || error "VKPR Postgresql not found"
}

removePVC(){
  if [[ $DELETE_PVC == true ]]; then
    info "Removing PVC..."
    
    $VKPR_KUBECTL delete pvc -A -l app.kubernetes.io/instance=postgresql
  fi
}
