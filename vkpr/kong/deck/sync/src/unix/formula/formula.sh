#!/bin/bash

runFormula() {
  if $(deck ping --kong-addr=$KONG_ADDR --headers=Kong-Admin-Token:$KONG_ADMIN_TOKEN | grep -q "Successfully"); then
    if [[ "$KONG_WORKSPACE" == "default" ]]; then
        bold "$(error "WARNING! we do not recommend SYNC in the default workspace")"
    fi
    if $(deck validate -s $KONG_YAML_PATH 2>&1 | grep -q "Error:"); then
        bold "$(error "File contains errors, check your kong.yaml")"
    else
      notice "Successfully connected to Kong!"
      deck sync -s $KONG_YAML_PATH --workspace $KONG_WORKSPACE --kong-addr=$KONG_ADDR --headers=Kong-Admin-Token:$KONG_ADMIN_TOKEN 
      info "Kong SYNC successfully executed"
    fi
  fi
}
