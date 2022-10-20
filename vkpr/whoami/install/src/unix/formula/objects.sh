#!/usr/bin/env bash

dryRunK8s(){
  if [ $DRY_RUN = true ]; then
    trace "Creating file $CURRENT_PWD/$1.yaml by dry_run=true"
    echo "--dry-run=client -o=yaml > $CURRENT_PWD/$1.yaml"
    return 0
  fi
  echo "> /dev/null"
}

createSecretTLS(){
  SECRET_NAME="whoami-certificate"

  trace "Creating TLS secret with name $SECRET_NAME"
  eval $VKPR_KUBECTL create secret tls $SECRET_NAME -n "$VKPR_ENV_WHOAMI_NAMESPACE" \
    --cert="$VKPR_ENV_WHOAMI_SSL_CERTIFICATE" \
    --key="$VKPR_ENV_WHOAMI_SSL_KEY" $(dryRunK8s "tls-secret")

  RESULT=$?
  debug "Create TLS secret status = $RESULT"
  [ $RESULT -eq 0 ] && trace "$($VKPR_KUBECTL label secret/whoami-certificate app\.kubernetes\.io/managed-by=vkpr -n "$VKPR_ENV_WHOAMI_NAMESPACE")"

  echo "$SECRET_NAME"
}
