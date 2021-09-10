#!/bin/sh

runFormula() {
  echoColor "green" "Output global config template."
  outputGlobalTemplate
}

outputGlobalTemplate(){
  if [[ ! -s $VKPR_GLOBAL ]]; then
    echoColor "red" "Doesnt have any values in global config file."
    else
    $VKPR_YQ eval $VKPR_GLOBAL
  fi
}
