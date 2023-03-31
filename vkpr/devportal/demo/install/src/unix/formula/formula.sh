#!/usr/bin/env bash

runFormula() {

  VKPR_DEVPORTAL_VALUES=$(dirname "$0")/utils/devportal.yaml

  startInfos
  settingOktetoNamespace
  setCredentials
  settingDevportal

  [ $DRY_RUN = false ] && installDB
  [ $DRY_RUN = false ] && registerHelmRepository veecode-platform https://veecode-platform.github.io/public-charts/
  installApplication "devportal" "veecode-platform/devportal" "$OKTETO_NAMESPACE" "$VKPR_DEVPORTAL_VERSION" "$VKPR_DEVPORTAL_VALUES" "$HELM_ARGS"
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Devportal demo Install Routine"
  bold "=============================="
}

setCredentials() {
  GITHUB_TOKEN="$($VKPR_JQ -r '.credential.token' $VKPR_CREDENTIAL/github)"
}

settingDevportal() {
  YQ_VALUES=".appConfig.app.baseUrl = \"https://devportal-$NAMESPACE.cloud.okteto.net\" |
      .appConfig.backend.baseUrl = \"https://devportal-$NAMESPACE.cloud.okteto.net\" |
      .auth.providers.github.clientId = \"$GITHUB_CLIENT_ID\" |
      .auth.providers.github.clientSecret = \"$GITHUB_CLIENT_SECRET\" |
      .integrations.github.token = \"$GITHUB_TOKEN\" |
      .catalog.providers.github.organization = \"$GITHUB_CLIENT_ORGANIZATION\"
  "
  debug "YQ_CONTENT = $YQ_VALUES"
}

installDB(){
  if [[ $(checkPodName "$VKPR_ENV_POSTGRESQL_NAMESPACE" "postgres-postgresql") != "true" ]]; then
    info "Initializing postgresql to Devportal"
    [[ -f $CURRENT_PWD/vkpr.yaml ]] && cp "$CURRENT_PWD"/vkpr.yaml "$(dirname "$0")"
    rit vkpr postgresql install --default
  else
    info "Initializing Devportal with Postgres already created"
  fi
}

settingOktetoNamespace(){
  if [[ "$OKTETO_NAMESPACE" == "null" ]]; then
    export CONTEXT=$($VKPR_OKTETO namespace list | grep Active)
    export NAMESPACE="$(echo $CONTEXT | awk -F' ' '{print $1}')"
    debug "NAMESPACE: $NAMESPACE"

    $VKPR_OKTETO namespace use "$NAMESPACE"
  else  
    export NAMESPACE=$OKTETO_NAMESPACE
    debug "NAMESPACE: $NAMESPACE"

    $VKPR_OKTETO namespace use "$OKTETO_NAMESPACE"
  fi
}