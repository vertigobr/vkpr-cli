#!/bin/bash

runFormula() {
  if $VKPR_DECK ping --kong-addr="$KONG_ADDR" --headers=Kong-Admin-Token:"$KONG_ADMIN_TOKEN" | grep -q "Successfully"; then
    notice "Successfully connected to Kong!"
    if [[ "$KONG_WORKSPACE" == "default" ]]; then
      error "WARNING! we do not recommend DUMP in the default workspace"
      sleep 5
    fi
    $VKPR_DECK dump -w "$KONG_WORKSPACE" --kong-addr="$KONG_ADDR" --headers=Kong-Admin-Token:"$KONG_ADMIN_TOKEN"
    info "Kong DUMP successfully executed"
  else
    error "Unable to connect with Kong!"
  fi
}
