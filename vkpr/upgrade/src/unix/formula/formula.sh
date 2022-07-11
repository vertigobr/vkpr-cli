#!/bin/bash

runFormula() {
  boldInfo "Updating VKPR repository..."
  rit update repo --name="vkpr-cli"
  rit vkpr init
}
