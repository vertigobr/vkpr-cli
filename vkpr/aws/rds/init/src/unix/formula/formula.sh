#!/usr/bin/env bash

runFormula() {

  echo $PROVIDER

  case $PROVIDER in
    awscli)
      source "$(dirname "$0")"/unix/formula/awscli.sh 
      setproviderrun
      ;;
    terraform)
      source "$(dirname "$0")"/unix/formula/terraform.sh
      setproviderrun
      ;;
    esac
}
