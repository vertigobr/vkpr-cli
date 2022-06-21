#!/bin/bash

runFormula() {
  bold "$(info "Updating VKPR repository...")"
  rit update repo --name="vkpr-cli"
  rit vkpr init
}
