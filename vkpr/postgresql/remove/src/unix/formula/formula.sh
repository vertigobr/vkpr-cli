#!/usr/bin/env bash

runFormula() {
  removePostgres
  removePVC
}

removePostgres(){
  info "Removing Postgresql..."

  HELM_FLAG="-A"
  [[ "$VKPR_ENVIRONMENT" == "okteto" ]] && HELM_FLAG=""
  POSTGRESQL_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG |\
                     $VKPR_JQ -r '.[] | select(.name | contains("postgresql")) | .namespace' |\
                     head -n1)

  $VKPR_HELM uninstall --namespace "$POSTGRESQL_NAMESPACE" postgresql 2> /dev/null || error "VKPR Postgresql not found"
}

removePVC(){
  if [[ $DELETE_PVC == true ]]; then
    info "Removing PVC..."

    $VKPR_KUBECTL delete pvc -A -l app.kubernetes.io/instance=postgresql
  fi
}
