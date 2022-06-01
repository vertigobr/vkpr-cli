#!/bin/bash

runFormula() {
  if $(deck ping --kong-addr=$KONG_ADDR --headers=Kong-Admin-Token:$KONG_ADMIN_TOKEN | grep -q "Successfully"); then
      notice "Successfully connected to Kong!"
      if [[ "$KONG_WORKSPACE" == "default" ]]; then
        bold "$(error "WARNING! we do not recommend DUMP in the default workspace")"
      fi
      deck dump -w $KONG_WORKSPACE --kong-addr=$KONG_ADDR --headers=Kong-Admin-Token:$KONG_ADMIN_TOKEN
      info "Kong DUMP successfully executed"
  else
    bold "$(error "Unable to connect with Kong!")"
  fi
}