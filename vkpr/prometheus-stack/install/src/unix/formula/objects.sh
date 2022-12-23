#!/usr/bin/env bash

createSslSecret() {
  local SECRET_NAME=$1 \
        NAMESPACE=$2 \
        PATH_CRT=$3 \
        PATH_KEY=$4

  if [[ $DRY_RUN = true ]]; then
  $VKPR_KUBECTL create secret tls $SECRET_NAME -n "$NAMESPACE"  \
    --cert=$PATH_CRT \
    --key=$PATH_KEY \
    --dry-run=client -o=yaml > $CURRENT_PWD/$1.yaml

  else
    $VKPR_KUBECTL create secret tls $SECRET_NAME  -n "$NAMESPACE" \
      --cert=$PATH_CRT \
      --key=$PATH_KEY 
  fi

  RESULT=$?
  debug "Create $SECRET_NAME secret status = $RESULT"
  [ $DRY_RUN = false ] && trace "$($VKPR_KUBECTL label secret/$SECRET_NAME app\.kubernetes\.io/managed-by=vkpr -n "$NAMESPACE")"
  debug "$SECRET_NAME"
}

