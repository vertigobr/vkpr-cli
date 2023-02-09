#!/usr/bin/env bash

## Creates a variable with the value that follows the stipulated precedence
## formula input -> values file -> env -> default values
# Parameters:
# 1 - INPUT_VALUE
# 2 - DEFAULT_INPUT_VALUE
# 3 - VALUES_LABEL_PATH
# 4 - ENV_NAME
checkGlobalConfig(){
  local INPUT_VALUE="$1" DEFAULT_INPUT_VALUE="$2" \
        VALUES_LABEL_PATH=".$3" ENV_NAME="VKPR_ENV_$4"

  if [ "$INPUT_VALUE" != "$DEFAULT_INPUT_VALUE" ]; then
    warn "Setting value from input value: $ENV_NAME"
    eval "$ENV_NAME"="$INPUT_VALUE"
    return
  fi

  if [ -f "$VKPR_FILE" ] && [ "$($VKPR_YQ eval "$VALUES_LABEL_PATH" "$VKPR_FILE")" != "null" ]; then
    warn "Setting value from config file: $ENV_NAME"
    eval "$ENV_NAME"=\"$($VKPR_YQ eval "$VALUES_LABEL_PATH | . style=\"flow\"" "$VKPR_FILE")\"
    return
  fi

  if printenv | grep -q "$ENV_NAME"; then
    warn "Setting value from env: $ENV_NAME"
    eval "$ENV_NAME"="$(printf '%s\n' "${!ENV_NAME}")"
    return
  fi

  if [ "$INPUT_VALUE" == "$DEFAULT_INPUT_VALUE" ]; then
    warn "Setting value from default value: $ENV_NAME"
    eval "$ENV_NAME"="$INPUT_VALUE"
    return
  fi
}

globalInputs() {
  checkGlobalConfig "${DOMAIN:-localhost}" "localhost" "global.domain" "GLOBAL_DOMAIN"
  checkGlobalConfig "${SECURE:-false}" "false" "global.secure" "GLOBAL_SECURE"
  checkGlobalConfig "nginx" "nginx" "global.ingressClassName" "GLOBAL_INGRESS_CLASS_NAME"
  checkGlobalConfig "vkpr" "vkpr" "global.namespace" "GLOBAL_NAMESPACE"
  checkGlobalConfig "" "" "global.provider" "GLOBAL_PROVIDER"
}

## Merge KV from the helmArgs key by the VKPR values into application values
# Parameters:
# 1 - APP_NAME
# 2 - APP_VALUES
mergeVkprValuesHelmArgs() {
  local APP_NAME="$1" APP_VALUES="$2"

  [[ ! -f "$VKPR_FILE" ]] && return

  if [[ $($VKPR_YQ eval ".${APP_NAME} | has (\"helmArgs\")" "$CURRENT_PWD"/vkpr.yaml) == true ]]; then
    cp "$CURRENT_PWD"/vkpr.yaml "$(dirname "$0")"/vkpr-cp.yaml

    # foreach key in helmargs, merge the values into application value
    for i in $($VKPR_YQ eval ".${APP_NAME}.helmArgs | keys" "$CURRENT_PWD"/vkpr.yaml | cut -d " " -f2); do
      $VKPR_YQ eval-all -i \
        ". * {\"${i}\": select(fileIndex==1).${APP_NAME}.helmArgs.${i}} | select(fileIndex==0)" \
        "$APP_VALUES" "$(dirname "$0")"/vkpr-cp.yaml
    done
    rm "$(dirname "$0")"/vkpr-cp.yaml

  fi
}

mergeVkprValuesExtraArgs() {
  local APP_NAME="$1" APP_VALUES="$2"

  [[ ! -f "$VKPR_FILE" ]] && return

  if [[ $($VKPR_YQ eval ".${APP_NAME} | has (\"extraArgs\")" "$CURRENT_PWD"/vkpr.yaml) == true ]]; then
    cp "$CURRENT_PWD"/vkpr.yaml "$(dirname "$0")"/vkpr-cp.yaml

    # foreach key in extraArgs, merge the values into application value
    for i in $($VKPR_YQ eval ".${APP_NAME}.extraArgs | keys" "$CURRENT_PWD"/vkpr.yaml | cut -d " " -f2); do
      $VKPR_YQ eval-all -i \
        ". * {\"${i}\": select(fileIndex==1).${APP_NAME}.extraArgs.${i}} | select(fileIndex==0)" \
        "$APP_VALUES" "$(dirname "$0")"/vkpr-cp.yaml
    done
    rm "$(dirname "$0")"/vkpr-cp.yaml

  fi

}

## Encode text
# Parameters:
# 1 - STRING
rawUrlEncode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"    # You can either set a return variable (FASTER)
  REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}

verifyActualEnv() {
  ACTUAL_CONTEXT=$($VKPR_KUBECTL config get-contexts --no-headers | grep "\*" | xargs | awk -F " " '{print $2}')
  if [[ "$VKPR_ENV_GLOBAL_PROVIDER" == "okteto" ]] || [[ $ACTUAL_CONTEXT == "cloud_okteto_com" ]]; then
    eval "VKPR_ENVIRONMENT"="okteto"
  fi
}

