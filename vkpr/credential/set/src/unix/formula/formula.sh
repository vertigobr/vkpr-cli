#!/usr/bin/env bash

runFormula() {
  if [[ "$LIST_PROVIDER" != "Add a new" ]]; then
    export PROVIDER=LIST_PROVIDER
  fi

  GREP_PROVIDER=$(ls $HOME/.rit/credentials/default | grep $PROVIDER)
  debug "PROVIDER = $PROVIDER"
  debug "GREP_PROVIDER = $GREP_PROVIDER"

  if [[ $GREP_PROVIDER == $PROVIDER ]]; then
    error "This provider has already been added before, you can remove it by running 'vkpr credential delete --provider=$PROVIDER'"
    return 1
  fi

  info "Creating credentials on rit..."
  rit set credential --provider="$PROVIDER" --fields="$FIELDS" --values="$VALUES" > /dev/null 

  boldInfo "$PROVIDER credential saved!"
  bold "Check your credentials using vkpr credential list"

}
