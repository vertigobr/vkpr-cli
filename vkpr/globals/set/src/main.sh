#!/bin/bash

if [ ! -d $CURRENT_PWD/global ]; then
  echo "Doesn't initializated the vkpr... Call again the function"
  rit vkpr init
  exit;
fi

source $CURRENT_PWD/global/log.sh
source $CURRENT_PWD/global/var.sh

# shellcheck source=/dev/null
. "$(dirname "$0")"/unix/formula/formula.sh --source-only

runFormula