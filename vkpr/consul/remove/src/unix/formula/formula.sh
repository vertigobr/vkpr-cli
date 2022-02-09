#!/bin/bash

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing Consul...")"
  CONSUL_NAMESPACE=$($VKPR_KUBECTL get po -A -l app=consul,vkpr=true -o=yaml | $VKPR_YQ e ".items[].metadata.namespace" - | head -n1)
  $VKPR_HELM uninstall consul -n $CONSUL_NAMESPACE 2> /dev/null
}
