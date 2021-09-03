#!/bin/bash

VKPR_GLOBALS=~/.vkpr/global

source $VKPR_GLOBALS/log.sh
source $VKPR_GLOBALS/var.sh
source $VKPR_GLOBALS/helper.sh

# shellcheck source=/dev/null
. "$(dirname "$0")"/unix/formula/formula.sh --source-only

runFormula
