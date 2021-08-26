#!/bin/sh

runFormula() {
  echoColor "green" "Output global config template."
  outputGlobalTemplate
}

outputGlobalTemplate(){
  $VKPR_YQ eval $VKPR_GLOBALS/global-values.yaml
}
