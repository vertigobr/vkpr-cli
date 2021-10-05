#!/bin/bash

##Import Log functions
. "$(dirname "$0")"/utils/log.sh

##Import VARS
. "$(dirname "$0")"/utils/var.sh

# shellcheck source=/dev/null
. "$(dirname "$0")"/unix/formula/formula.sh --source-only

runFormula
