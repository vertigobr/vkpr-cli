#!/usr/bin/env bash

runFormula() {
  
  export BASIC_AUTH_HEADER
  BASIC_AUTH_HEADER="$(echo kong_admin:$KONG_ADMIN_TOKEN | base64)"
  debug "BASIC_AUTH_HEADER=$BASIC_AUTH_HEADER"

  if $VKPR_DECK ping --kong-addr="$KONG_ADDR" --headers=Kong-Admin-Token:"$KONG_ADMIN_TOKEN" --headers="Authorization: Basic $BASIC_AUTH_HEADER" | grep -q "Successfully"; then
    notice "Successfully connected to Kong!"
    if [[ "$KONG_WORKSPACE" == "default" ]]; then
      error "WARNING! we do not recommend DUMP in the default workspace"
      sleep 2
    fi
    $VKPR_DECK dump -w "$KONG_WORKSPACE" --kong-addr="$KONG_ADDR" --headers=Kong-Admin-Token:"$KONG_ADMIN_TOKEN" --headers="Authorization: Basic $BASIC_AUTH_HEADER"
    info "Kong DUMP successfully executed"
  else
    error "Unable to connect with Kong!"
  fi
}
