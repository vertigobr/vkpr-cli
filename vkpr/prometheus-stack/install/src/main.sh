#!/usr/bin/env bash

# shellcheck source=/dev/null
source src/lib/load.sh "validator"
source src/lib/load.sh "functions"
source src/lib/log.sh
source src/lib/var.sh
source src/lib/versions.sh
source src/lib/scripts/prometheus-stack/commands-operators.sh

source "$(dirname "$0")"/unix/formula/objects.sh
source "$(dirname "$0")"/unix/formula/inputs.sh
source "$(dirname "$0")"/unix/formula/setting/alertmanager.sh
source "$(dirname "$0")"/unix/formula/setting/grafana.sh
source "$(dirname "$0")"/unix/formula/setting/prometheus.sh
source "$(dirname "$0")"/unix/formula/setting/prometheus-stack.sh

. "$(dirname "$0")"/unix/formula/formula.sh --source-only

globalInputs
verifyActualEnv
runFormula
