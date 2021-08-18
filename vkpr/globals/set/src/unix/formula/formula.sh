#!/bin/bash

runFormula() {
  VKPR_GLOBAL_TYPE=$GLOBAL_TYPE
  VKPR_GLOBAL_NAME=$(echo "$NAME" | tr '[a-z]' '[A-Z]')
  VKPR_GLOBAL_CONTENT=$CONTENT

  case $VKPR_GLOBAL_TYPE in
    credential)
      createEnvCredential
      ;;
    file)
      createEnvFile
      ;;
  esac
}

createEnvCredential() {
  read -p "$(echoColor "bold" "$(echoColor "green" "?")") $(echoColor "bold" "Type of provider : (vkpr)")" VKPR_GLOBAL_PROVIDER
  VKPR_GLOBAL_PROVIDER=${VKPR_GLOBAL_PROVIDER:-vkpr}
  rit set credential --provider=$VKPR_GLOBAL_PROVIDER --fields="$VKPR_GLOBAL_NAME" --values="$VKPR_GLOBAL_CONTENT"
}

createEnvFile() {
  if [ ! -d $VKPR_GLOBALS ]; then
    mkdir -p $VKPR_GLOBALS
  fi
  if [ ! -z $VKPR_GLOBAL_NAME ]; then
    printf "VKPR_ENV_$VKPR_GLOBAL_NAME=$VKPR_GLOBAL_CONTENT\n" >> $VKPR_GLOBALS/.env
  fi
}