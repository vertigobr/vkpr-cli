#!/bin/sh

#
# Downloads tools and other CLIs used transparently
#
# Trying to use `arkade` when possible
#
# Requires: curl

# OS/PLATFORM DETECTION
OS_PLATFORM=$(uname -m)
if [[ "$OS_PLATFORM" == "x86_64" ]]; then
  OS_ARCH="amd64"
else # arm64
  OS_ARCH="$OS_PLATFORM"
fi

# ARKADE

#KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
#if [[ "$OSTYPE" == "darwin"* ]]; then # osx intel or arm
#  KUBECTL_URL="https://dl.k8s.io/release/$KUBECTL_VERSION/bin/darwin/$OS_ARCH/kubectl"
#else # linux
#  KUBECTL_URL="https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
#fi


TOOLS_ARRAY=('kubectl' 'k3d' 'helm')

runFormula() {
  echo "VKPR initialization"
  # VKPR home is "~/.vkpr"
  VKPR_HOME=~/.vkpr
  # required paths
  mkdir -p $VKPR_HOME/bin

  installArkade

  # if [ "$RIT_INPUT_BOOLEAN" = "true" ]; then
  #   echoColor "blue" "I've already created formulas using Ritchie."
  # else
  #   echoColor "red" "I'm excited in creating new formulas using Ritchie."
  # fi

  # echoColor "yellow" "Today, I want to automate $RIT_INPUT_LIST."
  # echoColor "cyan"  "My secret is $RIT_INPUT_PASSWORD."
}

installArkade() {
  echoColor "green" "Installing arkade..."
  # patches download script in order to change BINLOCATION
  curl -sLS https://get.arkade.dev > /tmp/arkinst.sh
  sed "s/^export BINLOCATION=.*/export BINLOCATION=~\/\.vkpr\/bin/g" -i /tmp/arkinst.sh
  chmod +x /tmp/arkinst.sh
  /tmp/arkinst.sh  
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
