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
  # required paths
  mkdir -p $VKPR_HOME/bin
  mkdir -p $VKPR_HOME/config

  installArkade
  installTool "kubectl"
  installTool "helm"
  installTool "k3d"
  installTool "jq"
  installTool "yq"
  installTool "k9s"

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
  if [[ -f "$HOME/.vkpr/bin/$toolName" ]]; then
    echoColor "yellow" "Tool $toolName already installed. Skipping."
  else
    echoColor "green" "Installing $toolName using arkade..."
    $VKPR_HOME/bin/arkade get "$toolName" --stash=true
    mv "$HOME/.arkade/bin/$toolName" $VKPR_HOME/bin
  fi
}

installArkade() {
  if [[ -f "$HOME/.vkpr/bin/arkade" ]]; then
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
