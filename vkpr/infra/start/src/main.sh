#!/bin/bash

# shellcheck source=/dev/null
. "$(dirname "$0")"/unix/formula/formula.sh --source-only

source ~/.vkpr/global/log.sh
source ~/.vkpr/global/var.sh

runFormula
