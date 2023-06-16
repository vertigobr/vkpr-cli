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
    $VKPR_YQ eval -i "$YQ_VALUES" "$APP_VALUES"
    mergeVkprValuesHelmArgs "$APP_NAME" "$APP_VALUES"
    $VKPR_YQ eval $APP_VALUES
    return
  fi

  if [[ $DIFF == true ]]; then
    bold "=============================="
    info "The $APP_NAME application chart diff is in version $APP_VERSION"
    if echo "$($VKPR_HELM ls -qA)" | grep -q "$APP_NAME"; then
      local HELM_OLD_VERSION=$($VKPR_HELM ls -A | grep $APP_NAME | awk -F' ' '{print $9}'| awk -F'-' '{print $NF}')
      infoYellow "The current version is $HELM_OLD_VERSION" 
    fi
    bold "=============================="
    $VKPR_YQ eval -i "$YQ_VALUES" "$APP_VALUES"
    mergeVkprValuesHelmArgs "$APP_NAME" "$APP_VALUES"

    if [[ $VKPR_PLAN == true ]]; then
      echo "==================================================================" >> /tmp/diff.txt
      echo "               VKPR Diff for $APP_NAME application" >> /tmp/diff.txt
      echo "==================================================================" >> /tmp/diff.txt

    fi

    $VKPR_HELM diff upgrade \
      --version "$APP_VERSION" \
      --namespace $APP_NAMESPACE \
      --values "$APP_VALUES" "$APP_NAME" "$APP_CHART" \
      --allow-unreleased --disable-validation >> /tmp/diff.txt 

    if [[ $VKPR_PLAN != true ]]; then
      echo "==================================================================" >> /tmp/diff.txt
      echo "            type :q and press enter to exit" >> /tmp/diff.txt
      echo "==================================================================" >> /tmp/diff.txt
      vi -R /tmp/diff.txt
      rm /tmp/diff.txt
    fi
    return 0
  fi
  
  info "Installing $APP_NAME..."
  $VKPR_YQ eval -i "$YQ_VALUES" "$APP_VALUES"
  mergeVkprValuesHelmArgs "$APP_NAME" "$APP_VALUES"

  if [ -z $HELM_ARGS ]; then
    trace "var HELM_ARGS without content"

    if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then 
      $VKPR_HELM upgrade -i --atomic --cleanup-on-fail \
      --timeout 10m --version "$APP_VERSION" \
      --namespace $APP_NAMESPACE \
      --values "$APP_VALUES" "$APP_NAME" "$APP_CHART"
    else
      $VKPR_HELM upgrade -i --atomic --cleanup-on-fail \
      --timeout 10m --version "$APP_VERSION" \
      --create-namespace --namespace $APP_NAMESPACE \
      --values "$APP_VALUES" "$APP_NAME" "$APP_CHART"
    fi
    
  else
    trace "var HELM_ARGS with content"
    $VKPR_HELM upgrade -i $HELM_ARGS \
     --timeout 10m --version "$APP_VERSION" \
     --values "$APP_VALUES" "$APP_NAME" "$APP_CHART"
  fi
}
