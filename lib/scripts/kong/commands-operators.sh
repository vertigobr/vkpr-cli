#!/usr/bin/env bash

checkComands (){
  COMANDS_EXISTS=$($VKPR_YQ eval ".kong | has(\"commands\")" "$VKPR_FILE" 2> /dev/null)
  debug "$COMANDS_EXISTS"
  if [ "$COMANDS_EXISTS" == true ]; then
    bold "=============================="
    boldInfo "Checking additional kong commands..."
    if [ $($VKPR_YQ eval ".kong.commands | has(\"sync\")" "$VKPR_FILE") == true ]; then
      checkGlobalConfig "" "" "kong.commands.sync.addr" "KONG_ADDR"
      checkGlobalConfig "" "" "kong.commands.sync.adminToken" "KONG_ADMIN_TOKEN"
      checkGlobalConfig "" "" "kong.commands.sync.workspace" "KONG_WORKSPACE"
      checkGlobalConfig "" "" "kong.commands.sync.yamlPath" "KONG_YAML_PATH"
      kongDeckSync "$VKPR_ENV_KONG_ADDR" "$VKPR_ENV_KONG_ADMIN_TOKEN" "$VKPR_ENV_KONG_WORKSPACE" "$VKPR_ENV_KONG_YAML_PATH"

    fi
  fi
}

kongDeckSync() {
  local KONG_ADDR=$1 \
        KONG_ADMIN_TOKEN=$2 \
        KONG_WORKSPACE=$3 \
        KONG_YAML_PATH=$4 \
        BASIC_AUTH_HEADER

  validateKongAddr "$KONG_ADDR"
  validateKongAdminToken "$KONG_ADMIN_TOKEN"
  validateKongWorkspace "$KONG_WORKSPACE"
  validateKongYamlPath "$KONG_YAML_PATH"

  BASIC_AUTH_HEADER="$(echo kong_admin:$KONG_ADMIN_TOKEN | base64)"
  debug "BASIC_AUTH_HEADER=$BASIC_AUTH_HEADER"

  info "Attempting to connect to Kong..."
  local i=0 \
        timeout=10
  while [[ $i -lt $timeout ]]; do
    if $VKPR_DECK ping --kong-addr="$KONG_ADDR" --headers=Kong-Admin-Token:"$KONG_ADMIN_TOKEN" --headers="Authorization: Basic $BASIC_AUTH_HEADER" | grep -q "Successfully"; then
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

  if $VKPR_DECK ping --kong-addr="$KONG_ADDR" --headers=Kong-Admin-Token:"$KONG_ADMIN_TOKEN" --headers="Authorization: Basic $BASIC_AUTH_HEADER" | grep -q "Successfully"; then
    notice "Successfully connected to Kong!"
    if [[ "$KONG_WORKSPACE" == "default" ]]; then
      error "WARNING! we do not recommend SYNC in the default workspace"
      sleep 5
    fi
    if $VKPR_DECK validate -s "$KONG_YAML_PATH" 2>&1 | grep -q "Error:"; then
      error "File contains errors, check your kong values"
      exit
    else
      $VKPR_DECK sync -s "$KONG_YAML_PATH" --workspace "$KONG_WORKSPACE" --kong-addr="$KONG_ADDR" --headers=Kong-Admin-Token:"$KONG_ADMIN_TOKEN" --headers="Authorization: Basic $BASIC_AUTH_HEADER"
      info "Kong SYNC successfully executed"
    fi
  fi
}
