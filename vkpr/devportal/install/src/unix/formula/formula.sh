#!/usr/bin/env bash

runFormula() {
  local VKPR_ENV_DEVPORTAL_DOMAIN VKPR_DEVPORTAL_VALUES HELM_ARGS KEYCLOAK_METADATA_URL;

  formulaInputs
  validateInputs

  VKPR_ENV_DEVPORTAL_DOMAIN="devportal.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_DEVPORTAL_VALUES=$(dirname "$0")/utils/devportal.yaml

  startInfos
  settingDevportal
  [ $DRY_RUN = false ] && registerHelmRepository veecode-platform https://veecode-platform.github.io/public-charts/
  installApplication "devportal" "veecode-platform/devportal" "$VKPR_ENV_DEVPORTAL_NAMESPACE" "$VKPR_DEVPORTAL_VERSION" "$VKPR_DEVPORTAL_VALUES" "$HELM_ARGS"
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Devportal Install Routine"
  boldNotice "Domain: $VKPR_ENV_DEVPORTAL_DOMAIN"
  boldNotice "Secure: $VKPR_ENV_GLOBAL_SECURE"
  boldNotice "Namespace: $VKPR_ENV_DEVPORTAL_NAMESPACE"
  boldNotice "Ingress Controller: $VKPR_ENV_DEVPORTAL_INGRESS_CLASS_NAME"
  bold "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "devportal.ingressClassName" "DEVPORTAL_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "devportal.namespace" "DEVPORTAL_NAMESPACE"
  checkGlobalConfig "$PROVIDER" "" "devportal.provider" "CATALOG_PROVIDER"
  checkGlobalConfig "$GIT_BRANCH" "" ".catalog.providers.branch" "GIT_BRANCH"
  checkGlobalConfig "$GIT_REPO" "" ".catalog.providers.repository" "GIT_REPO"
  checkGlobalConfig "$GITHUB_CLIENT_ID" "" ".auth.providers.github.clientId" "GITHUB_CLIENT_ID"
  checkGlobalConfig "$GITHUB_CLIENT_SECRET" "" ".auth.providers.github.clientSecret" "GITHUB_CLIENT_SECRET"
  checkGlobalConfig "$GITHUB_TOKEN" "" ".integrations.github.token" "GITHUB_TOKEN"
  checkGlobalConfig "$GITHUB_ORGANIZATION" "" ".catalog.providers.repository" "GITHUB_ORGANIZATION"
  checkGlobalConfig "$CLIENT_GROUPS" "" ".catalog.providers.gitlab.group" "CLIENT_GROUPS"
  checkGlobalConfig "$GITLAB_TOKEN" "" ".integrations.gitlab.token" "GITLAB_TOKEN"

}
validateInputs() {
  validateDevportalDomain "$VKPR_ENV_GLOBAL_DOMAIN"
  validateDevportalSecure "$VKPR_ENV_GLOBAL_SECURE"
  validateDevportalIngressClassName "$VKPR_ENV_DEVPORTAL_INGRESS_CLASS_NAME"
  validateDevportalNamespace "$VKPR_ENV_DEVPORTAL_NAMESPACE"
}

settingDevportal(){
  YQ_VALUES=".ingress.host = \"$VKPR_ENV_DEVPORTAL_DOMAIN\" |
    .ingress.className = \"$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME\" |
    .ingress.enabled = true |
    .appConfig.app.baseUrl = \"http://$VKPR_ENV_DEVPORTAL_DOMAIN/\" |
    .appConfig.backend.baseUrl = \"http://$VKPR_ENV_DEVPORTAL_DOMAIN/\" 
  "

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .ingress.tls.secretName = \"devportal-cert\" |
      .appConfig.app.baseUrl = \"https://$VKPR_ENV_DEVPORTAL_DOMAIN/\" |
      .appConfig.backend.baseUrl = \"https://$VKPR_ENV_DEVPORTAL_DOMAIN/\"
    "
  fi

  if [[ $VKPR_ENV_GLOBAL_DOMAIN == "localhost" ]]; then
    YQ_VALUES="$YQ_VALUES |
      .appConfig.app.baseUrl = \"http://$VKPR_ENV_DEVPORTAL_DOMAIN:8000/\" |
      .appConfig.backend.baseUrl = \"http://$VKPR_ENV_DEVPORTAL_DOMAIN:8000/\" |
      .platform.apiManagement.readOnlyMode = \"true\"
    "
  fi

  debug "CATALOG PROVIDER: $VKPR_ENV_CATALOG_PROVIDER"
  case $VKPR_ENV_CATALOG_PROVIDER in
    github)
      YQ_VALUES="$YQ_VALUES |
        del(.catalog.providers.gitlab) |
        .auth.providers.github.clientId = \"$VKPR_ENV_GITHUB_CLIENT_ID\" |
        .auth.providers.github.clientSecret = \"$VKPR_ENV_GITHUB_CLIENT_SECRET\" |
        .integrations.github.token = \"$VKPR_ENV_GITHUB_TOKEN\" |
        .catalog.providers.github.organization = \"$VKPR_ENV_CLIENT_ORGANIZATION\" |
        .catalog.providers.github.filters.repository = \"$VKPR_ENV_GIT_REPO\" |
        .catalog.providers.github.filters.branch = \"$VKPR_ENV_GIT_BRANCH\"
      "
    ;;
    gitlab)
      YQ_VALUES="$YQ_VALUES |
        del(.catalog.providers.github) |
        .integrations.gitlab.token = \"$VKPR_ENV_GITLAB_TOKEN\" |
        .catalog.providers.gitlab.group= \"$$VKPR_ENV_CLIENT_GROUPS\" |
        .catalog.providers.gitlab.projectPattern = \"$VKPR_ENV_GIT_REPO\" |
        .catalog.providers.gitlab.branch = \"$VKPR_ENV_GIT_BRANCH\" 
      "
    ;;
    *)
      error "Something wrong whit this provider"
    ;;
    esac
  debug "YQ_CONTENT = $YQ_VALUES"
}
