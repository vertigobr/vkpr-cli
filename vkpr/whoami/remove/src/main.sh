#!/bin/bash

source src/log.sh
source src/var.sh
source src/helper.sh
source src/validate.sh
source src/versions.sh

# shellcheck source=/dev/null
. "$(dirname "$0")"/unix/formula/formula.sh --source-only

runFormula
