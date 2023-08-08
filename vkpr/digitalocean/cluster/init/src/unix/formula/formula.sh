#!/usr/bin/env bash


runFormula() {

  echo $PROVIDER

  case $PROVIDER in
    github)
      source "$(dirname "$0")"/unix/formula/github.sh 
      runFormulaGithub
      ;;
    gitlab)
      source "$(dirname "$0")"/unix/formula/gitlab.sh
      runFormulaGitlab
      ;;
    esac
}

