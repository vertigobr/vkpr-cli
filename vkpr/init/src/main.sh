#!/bin/bash

# shellcheck source=/dev/null
source src/log.sh
source src/var.sh
source src/helper.sh
source src/validate.sh
source src/versions.sh
source "$(dirname "$0")"/utils/dependencies.sh

. "$(dirname "$0")"/unix/formula/formula.sh --source-only

runFormula
