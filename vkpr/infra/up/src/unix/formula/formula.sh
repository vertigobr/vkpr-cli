#!/bin/sh

runFormula() {
  cp $CURRENT_PWD/vkpr.yaml "$(dirname "$0")"
  rit vkpr infra start --default
}

