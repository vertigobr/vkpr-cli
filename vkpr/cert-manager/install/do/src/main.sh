#!/bin/bash

VKPR_SCRIPTS=~/.vkpr/src

source $VKPR_SCRIPTS/log.sh
source $VKPR_SCRIPTS/var.sh
source $VKPR_SCRIPTS/helper.sh

# TODO: detectar se já fez init
if [ ! -d ~/.vkpr/global ]; then
  echo "Din't initialize the vkpr cli. Please run `vkpr init`"
  exit;
fi

runFormula
