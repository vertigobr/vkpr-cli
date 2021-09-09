#!/bin/bash

# shellcheck source=/dev/null
. "$(dirname "$0")"/unix/formula/formula.sh --source-only

source ~/.vkpr/global/log.sh
source ~/.vkpr/global/var.sh

# TODO: detectar se já fez init
if [ ! -d ~/.vkpr/global ]; then
  echo "Din't initialize the vkpr cli. Please run `vkpr init`"
  exit;
fi

runFormula
