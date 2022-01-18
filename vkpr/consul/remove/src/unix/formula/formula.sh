#!/bin/bash

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing Consul...")"
  $VKPR_HELM uninstall consul -n $VKPR_K8S_NAMESPACE
}
