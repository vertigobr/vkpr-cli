#!/bin/sh

runFormula() {
  VKPR_WHOAMI_VALUES=$(dirname "$0")/utils/whoami.yaml

  checkGlobalConfig $DOMAIN "whoami.localhost" "domain"
  addRepoWhoami
  installWhoami
}

addRepoWhoami(){
  $VKPR_HELM repo add cowboysysop https://cowboysysop.github.io/charts/
  $VKPR_HELM repo update
}

installWhoami(){
  echoColor "yellow" "Installing whoami..."
  $VKPR_YQ eval '.ingress.hosts[0].host = "'$VKPR_ENV_DOMAIN'" | .ingress.tls[0].hosts[0] = "'$VKPR_ENV_DOMAIN'"' "$VKPR_WHOAMI_VALUES" \
 | $VKPR_HELM upgrade -i -f - whoami cowboysysop/whoami
}

#$1=global variable; $2=default value of the global variable; $3=label from config file
checkGlobalConfig(){
  CONFIG_FILE=$VKPR_GLOBALS/global-config.yaml
  file_label='.global.'$3
  if [ -f "$CONFIG_FILE" ] && [ $1 == $2 ] && [ $($VKPR_YQ eval $file_label $CONFIG_FILE) != "null" ]; then
      echoColor "yellow" "Setting value from config file"
      VKPR_ENV_DOMAIN=$($VKPR_YQ eval $file_label $CONFIG_FILE)
  else
    if [ $1 == $2 ]; then
      echoColor "yellow" "Setting value from default value"
      VKPR_ENV_DOMAIN=$1
    else
      echoColor "yellow" "Setting value from user input"
      VKPR_ENV_DOMAIN=$1
    fi
  fi
}