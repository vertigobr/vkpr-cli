#!/usr/bin/env bash

runFormula() {
  local VKPR_ENV_DEVPORTAL_DOMAIN VKPR_DEVPORTAL_VALUES HELM_ARGS KEYCLOAK_METADATA_URL;

  setCredentials
  formulaInputs
  validateInputs

  VKPR_ENV_DEVPORTAL_DOMAIN="devportal.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_DEVPORTAL_VALUES=$(dirname "$0")/utils/devportal.yaml
  KEYCLOAK_METADATA_URL="$KEYCLOAK_CLIENT_URL/realms/platform-devportal/.well-known/openid-configuration"

  [ $DRY_RUN = false ] && installDB
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

  # External apps values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "postgresql.namespace" "POSTGRESQL_NAMESPACE"
}

setCredentials() {
  POSTGRESQL_PWD="$($VKPR_JQ -r '.credential.password' $VKPR_CREDENTIAL/postgres 2> /dev/null)"
}

validateInputs() {
  validateDevportalDomain "$VKPR_ENV_GLOBAL_DOMAIN"
  validateDevportalSecure "$VKPR_ENV_GLOBAL_SECURE"
  validateDevportalIngressClassName "$VKPR_ENV_DEVPORTAL_INGRESS_CLASS_NAME"
  validateDevportalNamespace "$VKPR_ENV_DEVPORTAL_NAMESPACE"
}

settingDevportal() {
  YQ_VALUES=".ingress.host = \"$VKPR_ENV_DEVPORTAL_DOMAIN\" |
    .ingress.className = \"$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME\" |
    .appConfig.app.baseUrl = \"http://$VKPR_ENV_DEVPORTAL_DOMAIN/\" |
    .appConfig.backend.baseUrl = \"http://$VKPR_ENV_DEVPORTAL_DOMAIN/\" |
    .appConfig.database.connection.password = \"$POSTGRESQL_PWD\"
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

  if [[ $VKPR_ENV_GLOBAL_DOMAIN != "localhost" ]]; then
    case $CATALOG_PROVIDER in
      github)
        YQ_VALUES="$YQ_VALUES |
          .auth.providers.github.clientId = \"$GITHUB_CLIENT_ID\" |
          .auth.providers.github.clientSecret = \"$GITHUB_CLIENT_SECRET\" |
          .integrations.github.token = \"$GITHUB_TOKEN\" |
          .catalog.providers.github.organization = \"$CLIENT_ORGANIZATION\" |
          .catalog.providers.github.filters.branch = \"$CATALOG_BRANCH
        "
      ;;
      gitlab)
        YQ_VALUES="$YQ_VALUES |
          .integrations.gitlab.token = \"$GITLAB_TOKEN\" |
          .integrations.gitlab.apiBaseUrl = \"$GITLAB_APIBASEURL\" |
          .catalog.providers.gitlab.branch = \"$CATALOG_BRANCH\" |
          .catalog.providers.gitlab.orgEnabled = \"false\" |
          .catalog.providers.gitlab.orgEnabled = \"false\" |

        "
      ;;
      *)
        error "Something wrong whit this provider"
      ;;
    esac
  fi

  debug "YQ_CONTENT = $YQ_VALUES"
}

installDB(){
  debug "POSTGRESL NAMESPACE: $VKPR_ENV_POSTGRESQL_NAMESPACE"
  if [[ $(checkPodName "$VKPR_ENV_POSTGRESQL_NAMESPACE" "postgres-postgresql") != "true" ]]; then
    info "Initializing postgresql to Devportal"
    [[ -f $CURRENT_PWD/vkpr.yaml ]] && cp "$CURRENT_PWD"/vkpr.yaml "$(dirname "$0")"
    rit vkpr postgresql install --default
  else
    info "Initializing Devportal with Postgres already created"
  fi
}