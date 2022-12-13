#!/usr/bin/env bash

runFormula() {

 kongDeckSync "$KONG_ADDR" "$KONG_ADMIN_TOKEN" "$KONG_WORKSPACE" "$KONG_YAML_PATH"
 
}
