#!/usr/bin/env bash

## Register new repository when url does not exists in helm
# Parameters:
# 1 - REPO_NAME
# 2 - REPO_URL
registerHelmRepository(){
  local REPO_NAME="$1" \
        REPO_URL="$2"
  echo "Adding repository $REPO_NAME"
  $VKPR_HELM repo add "$REPO_NAME" "$REPO_URL" --force-update
}

installApplication() {
  local APP_NAME=$1 APP_CHART=$2 \
    APP_NAMESPACE=$3 APP_VERSION=$4 \
    APP_VALUES=$5 HELM_ARGS=$6

  if [[ $DRY_RUN == true ]]; then
    trace "App install with dry-run"
    bold "---"
    mergeVkprValuesHelmArgs "$APP_NAME" "$APP_VALUES"
    $VKPR_YQ eval "$YQ_VALUES" "$APP_VALUES"
    return
  fi

  info "Installing $APP_NAME..."
  $VKPR_YQ eval -i "$YQ_VALUES" "$APP_VALUES"
  mergeVkprValuesHelmArgs "$APP_NAME" "$APP_VALUES"

  if [ -z $HELM_ARGS ]; then
    trace "var HELM_ARGS without content"
    $VKPR_HELM upgrade -i --atomic --cleanup-on-fail \
     --timeout 10m --version "$APP_VERSION" \
     --create-namespace --namespace $APP_NAMESPACE \
     --values "$APP_VALUES" "$APP_NAME" "$APP_CHART"
  else
    trace "var HELM_ARGS with content"
    $VKPR_HELM upgrade -i $HELM_ARGS \
     --timeout 10m --version "$APP_VERSION" \
     --values "$APP_VALUES" "$APP_NAME" "$APP_CHART"
  fi
}
