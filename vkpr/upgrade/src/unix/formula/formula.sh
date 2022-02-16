#!/bin/bash

runFormula() {
  echoColor "green" "$(echoColor "bold" "Updating VKPR repository...")"
  rit update repo --name="vkpr-cli"
  rit vkpr init
}
