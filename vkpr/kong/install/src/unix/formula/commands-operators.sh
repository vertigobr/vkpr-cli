#!/usr/bin/env bash

kongDeckSync() {

  checkGlobalConfig "" "" "kong.commands.sync.addr" "KONG_ADDR"
  checkGlobalConfig "" "" "kong.commands.sync.adminToken" "KONG_ADMIN_TOKEN"
  checkGlobalConfig "" "" "kong.commands.sync.workspace" "KONG_WORKSPACE"
  checkGlobalConfig "" "" "kong.commands.sync.yamlPath" "KONG_YAML_PATH"

  validateKongAddr "$VKPR_ENV_KONG_ADDR"
  validateKongAdminToken "$VKPR_ENV_KONG_ADMIN_TOKEN"
  validateKongWorkspace "$VKPR_ENV_KONG_WORKSPACE"
  validateKongYamlPath "$VKPR_ENV_KONG_YAML_PATH"

  info "Attempting to connect to Kong..."
  local i=0 \
        timeout=10
  while [[ $i -lt $timeout ]]; do
    if $VKPR_DECK ping --kong-addr="$VKPR_ENV_KONG_ADDR" --headers=Kong-Admin-Token:"$VKPR_ENV_KONG_ADMIN_TOKEN" | grep -q "Successfully"; then
      break
    else
      sleep 1
      ((i++))
    fi
  done
  
  if [[ $i -ge $timeout ]]; then
    error "Could not connect to Kong!"
    exit
  fi

  if $VKPR_DECK ping --kong-addr="$VKPR_ENV_KONG_ADDR" --headers=Kong-Admin-Token:"$VKPR_ENV_KONG_ADMIN_TOKEN" | grep -q "Successfully"; then
    notice "Successfully connected to Kong!"
    if [[ "$VKPR_ENV_KONG_WORKSPACE" == "default" ]]; then
      error "WARNING! we do not recommend SYNC in the default workspace"
      sleep 5
    fi
    if $VKPR_DECK validate -s "$VKPR_ENV_KONG_YAML_PATH" 2>&1 | grep -q "Error:"; then
      error "File contains errors, check your kong values"
      exit
    else
      $VKPR_DECK sync -s "$VKPR_ENV_KONG_YAML_PATH" --workspace "$VKPR_ENV_KONG_WORKSPACE" --kong-addr="$VKPR_ENV_KONG_ADDR" --headers=Kong-Admin-Token:"$VKPR_ENV_KONG_ADMIN_TOKEN"
      info "Kong SYNC successfully executed"
    fi
  fi
}