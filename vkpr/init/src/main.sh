#!/bin/bash

#import utility
. "$(dirname "$0")"/utils/var.sh
. "$(dirname "$0")"/utils/log.sh
. "$(dirname "$0")"/utils/dependencies.sh

# shellcheck source=/dev/null
. "$(dirname "$0")"/unix/formula/formula.sh --source-only

runFormula
