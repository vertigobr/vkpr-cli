#!/usr/bin/env bash

runFormula() {
  [[ -f $CURRENT_PWD/vkpr.yaml ]] && cp "$CURRENT_PWD"/vkpr.yaml "$(dirname "$0")"
  rit vkpr infra start --default
}

