#!/bin/bash

if [ ! -d ~/.vkpr/global ]; then
  echo "Doesn't initializated the vkpr... Call again the function"
  rit vkpr init
  exit;
fi

source ~/.vkpr/global/log.sh
source ~/.vkpr/global/var.sh
#source ~/.vkpr/global/.env
#source ~/.vkpr/global/helper.sh

# shellcheck source=/dev/null
. "$(dirname "$0")"/unix/formula/formula.sh --source-only

runFormula
