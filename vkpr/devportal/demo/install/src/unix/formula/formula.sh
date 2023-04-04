#!/usr/bin/env bash

runFormula() {

  VKPR_DEVPORTAL_VALUES=$(dirname "$0")/utils/devportal.yaml

  startInfos
  settingOktetoNamespace
  setCredentials
  settingDevportal

  [ $DRY_RUN = false ] && installDB
  [ $DRY_RUN = false ] && registerHelmRepository veecode-platform https://veecode-platform.github.io/public-charts/

  installApplication "devportal" "veecode-platform/devportal" "$NAMESPACE" "$VKPR_DEVPORTAL_VERSION" "$VKPR_DEVPORTAL_VALUES"
  [ $DRY_RUN = false ] && endsInfos
}

startInfos() {
  bold "==================================="
  boldInfo "VKPR Devportal demo Install Routine"
  bold "==================================="
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
  [ $DRY_RUN = false ] && rit vkpr okteto init
  export NAMESPACE_LIST=$($VKPR_OKTETO namespace list | grep Active)
  export NAMESPACE="$(echo $NAMESPACE_LIST | awk -F' ' '{print $1}')"
  debug "NAMESPACE: $NAMESPACE"
}

endsInfos() {
  bold "=================================================================================="
  infoYellow "Your DevPortal is available at \"https://devportal-$NAMESPACE.cloud.okteto.net\""
  bold "=================================================================================="
}