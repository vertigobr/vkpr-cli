#!/bin/sh

runFormula() {
  echoColor "green" "Output global config template."
  outputGlobalTemplate
}

outputGlobalTemplate(){
  $VKPR_YQ eval $VKPR_HOME/global-values.yaml
}
