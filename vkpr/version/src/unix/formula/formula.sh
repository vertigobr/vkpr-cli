#!/usr/bin/env bash

runFormula() {
  if rit list repo | grep local > /dev/null; then
    export VKPR_VERSION_LOCAL="$(rit list repo | grep local | awk -F' ' '{print $3}')"
    export VKPR_REPO="$(rit list repo | grep local | awk -F' ' '{print $5}')"
    echo "vkpr-cli (local repository) version $VKPR_VERSION_LOCAL"
  fi
  
  if rit list repo | grep vkpr-cli > /dev/null; then
    export VKPR_VERSION="$(rit list repo | grep vkpr-cli | awk -F' ' '{print $3}')"
    export VKPR_REPO="$(rit list repo | grep vkpr-cli | awk -F' ' '{print $5}')"
    echo "vkpr-cli ($VKPR_REPO) version $VKPR_VERSION"
  fi
}
