#!/usr/bin/env bash

runFormula() {
  bold "$(info "Removing metric-server...")"
  uninstallMetric
}

uninstallMetric() {
   $VKPR_KUBECTL delete -f "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
}

