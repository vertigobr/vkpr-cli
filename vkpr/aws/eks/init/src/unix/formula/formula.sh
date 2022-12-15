#!/usr/bin/env bash


runFormula() {

  echo $PROVIDER

  case $PROVIDER in
    github)
      source "$(dirname "$0")"/unix/formula/github.sh 
      setproviderrun
      ;;
    gitlab)
      source "$(dirname "$0")"/unix/formula/gitlab.sh
      setproviderrun
      ;;
    esac
}

