#!/bin/sh

runFormula() {
  echoColor "green" "Removing Loki..."
  $VKPR_HELM uninstall vkpr-loki-stack
}
