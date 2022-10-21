#!/usr/bin/env bash

importDashboard() {
  local DASHBOARD_PATH=$1\
        PROMETHEUS_STACK_NAMESPACE=$2
  info "Importing dashboard..."
  createGrafanaDashboard "$DASHBOARD_PATH" "$PROMETHEUS_STACK_NAMESPACE"
}
