#!/bin/sh

#
# Downloads tools and other CLIs used transparently
#
# Trying to use `arkade` when possible
#
# Requires: curl

# # OS/PLATFORM DETECTION
# OS_PLATFORM=$(uname -m)
# if [[ "$OS_PLATFORM" == "x86_64" ]]; then
#   OS_ARCH="amd64"
# else # arm64
#   OS_ARCH="$OS_PLATFORM"
# fi

runFormula() {
  echo "VKPR initialization"
  # VKPR home is "~/.vkpr"
  VKPR_HOME=~/.vkpr
  VKPR_GLOBALS=$VKPR_HOME/global
  # required paths
  mkdir -p $VKPR_HOME/bin
  mkdir -p $VKPR_HOME/config
  mkdir -p $VKPR_HOME/test

  installArkade
  installTool "kubectl"
  installTool "helm"
  installTool "k3d"
  installTool "jq"
  installTool "yq"
  installTool "k9s"
  installGlobals
  installBats
  # if [ "$RIT_INPUT_BOOLEAN" = "true" ]; then
  #   echoColor "blue" "I've already created formulas using Ritchie."
  # else
  #   echoColor "red" "I'm excited in creating new formulas using Ritchie."
  # fi

  # echoColor "yellow" "Today, I want to automate $RIT_INPUT_LIST."
  # echoColor "cyan"  "My secret is $RIT_INPUT_PASSWORD."
} 

installTool() {
  toolName=$1
  if [[ -f "$VKPR_HOME/bin/$toolName" ]]; then
    echoColor "yellow" "Tool $toolName already installed. Skipping."
  else
    echoColor "green" "Installing $toolName using arkade..."
    $VKPR_HOME/bin/arkade get "$toolName" --stash=true
    mv "$HOME/.arkade/bin/$toolName" $VKPR_HOME/bin
  fi
}

installArkade() {
  if [[ -f "$VKPR_HOME/bin/arkade" ]]; then
    echoColor "yellow" "Alex Ellis' arkade already installed. Skipping."
  else
    echoColor "green" "Installing arkade..."
    # patches download script in order to change BINLOCATION
    curl -sLS https://get.arkade.dev > /tmp/arkinst0.sh
    sed "s/^export BINLOCATION=.*/export BINLOCATION=~\/\.vkpr\/bin/g" /tmp/arkinst0.sh > /tmp/arkinst.sh
    chmod +x /tmp/arkinst.sh
    rm /tmp/arkinst0.sh
    /tmp/arkinst.sh
  fi
}

installGlobals() {
  mkdir -p $VKPR_GLOBALS
  createPackagesFiles
}

installBats(){
  if [[ -f "$VKPR_HOME/bats/bin/bats" ]]; then
    echoColor "yellow" "Tool $toolName already installed. Skipping."
  else
    echoColor "green" "intalling bats..."
    mkdir -p /tmp/bats
    git clone https://github.com/bats-core/bats-core.git /tmp/bats-core
    /tmp/bats-core/install.sh $VKPR_HOME/bats
    rm -r --force /tmp/bats-core
    echoColor "green" "intalling bats add-ons..."
    git clone https://github.com/bats-core/bats-support $VKPR_HOME/bats/bats-support
    git clone https://github.com/bats-core/bats-assert $VKPR_HOME/bats/bats-assert
    git clone https://github.com/bats-core/bats-file $VKPR_HOME/bats/bats-file
  fi
}

createPackagesFiles() {
  touch $VKPR_GLOBALS/.env
  cp $(dirname "$0")/utils/* $VKPR_GLOBALS
}

echoColor() {
  case $1 in
    red)
      echo "$(printf '\033[31m')$2$(printf '\033[0m')"
      ;;
    green)
      echo "$(printf '\033[32m')$2$(printf '\033[0m')"
      ;;
    yellow)
      echo "$(printf '\033[33m')$2$(printf '\033[0m')"
      ;;
    blue)
      echo "$(printf '\033[34m')$2$(printf '\033[0m')"
      ;;
    cyan)
      echo "$(printf '\033[36m')$2$(printf '\033[0m')"
      ;;
    esac
}