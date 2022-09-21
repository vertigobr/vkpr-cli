#!/usr/bin/env bash

# shellcheck source=/dev/null
source src/lib/load.sh "validator"
source src/lib/load.sh "functions"
source src/lib/load.sh "scripts/argocd"
source src/lib/log.sh
source src/lib/var.sh
source src/lib/versions.sh

. "$(dirname "$0")"/unix/formula/formula.sh --source-only

globalInputs
verifyActualEnv
runFormula
