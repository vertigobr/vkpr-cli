#!/usr/bin/env bash

runFormula() {

  GREP_PROVIDER=$(ls $HOME/.rit/credentials/default | grep $PROVIDER)
  debug "PROVIDER = $PROVIDER"
  debug "GREP_PROVIDER = $GREP_PROVIDER"

  if [[ $GREP_PROVIDER != $PROVIDER ]]; then
    error "Provider not found, you can add it by running 'vkpr credential set --provider=$PROVIDER --fields=foo --values=bar'"
    return 1
  fi

  rit delete credential --provider=$PROVIDER  > /dev/null 

  boldInfo "Delete credential successful!"
  bold "Check your credentials using vkpr credential list"
}
