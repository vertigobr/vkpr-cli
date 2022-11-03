#!/usr/bin/env bash

source $(dirname "$0")/unix/formula/inputs.sh

runFormula() {
  formulaInputs
  setCredentials
  validateInputs

  case $PROVIDER in
    Gitlab)
      source $(dirname "$0")/unix/formula/gitlab.sh
      ;;
    Github)
      source $(dirname "$0")/unix/formula/github.sh
      ;;
  esac
}
