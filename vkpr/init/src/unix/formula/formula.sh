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
  VKPR_HOME=~/.vkpr
  VKPR_SCRIPTS=$VKPR_HOME/src
  
  mkdir -p $VKPR_HOME/bin
  mkdir -p $VKPR_HOME/config
  mkdir -p $VKPR_HOME/bats
  mkdir -p $VKPR_HOME/src

  installArkade
  installGlab
  #Versions from ./utils/dependencies.sh or latest as default
  installTool "kubectl" $VKPR_TOOLS_KUBECTL
  installTool "helm" $VKPR_TOOLS_HELM
  installTool "k3d" $VKPR_TOOLS_K3D
  installTool "jq" $VKPR_TOOLS_JQ
  installTool "yq" $VKPR_TOOLS_YQ
  installTool "k9s" $VKPR_TOOLS_K9S

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

##Install tool using arkade and get tools version from ./utils/dependencies.sh or latest as default
installTool() {
  local toolName=$1
  local toolVersion=$2
  if [[ -f "$VKPR_HOME/bin/$toolName" ]]; then
    echoColor "yellow" "Tool $toolName already installed. Skipping."
  else
    echoColor "green" "Installing $toolName@${toolVersion:-latest} using arkade..."
    $VKPR_HOME/bin/arkade get "$toolName@$toolVersion" --stash=true
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

installGlab() {
  if [[ -f "$VKPR_HOME/bin/glab" ]]; then
    echoColor "yellow" "Glab already installed. Skipping."
  else
    echoColor "green" "Installing Glab..."
    curl -sLS https://j.mp/glab-cli > /tmp/glab.sh
    chmod +x /tmp/glab.sh
    /tmp/glab.sh $VKPR_HOME/bin
  fi
}

installGlobals() {
  createPackagesFiles
}

installBats(){
  if [[ -f "$VKPR_HOME/bats/bin/bats" ]]; then
    echoColor "yellow" "Bats already installed. Skipping."
  else
    echoColor "green" "intalling Bats..."
    mkdir -p /tmp/bats
    # bats-core
    curl -sL -o /tmp/bats-core.tar.gz https://github.com/bats-core/bats-core/archive/refs/tags/v1.4.1.tar.gz
    tar -xzf /tmp/bats-core.tar.gz -C /tmp
    mv /tmp/bats-core-1.4.1 /tmp/bats-core
    /tmp/bats-core/install.sh $VKPR_HOME/bats
    rm -r --force /tmp/bats-core

    echoColor "green" "intalling bats add-ons..."
    # bats-support
    #git clone https://github.com/bats-core/bats-support $VKPR_HOME/bats/bats-support
    curl -sL -o /tmp/bats-support.tar.gz https://github.com/bats-core/bats-support/archive/refs/tags/v0.3.0.tar.gz
    tar -xzf /tmp/bats-support.tar.gz -C /tmp
    mv /tmp/bats-support-0.3.0 $VKPR_HOME/bats/bats-support
    # bats-assert
    curl -sL -o /tmp/bats-assert.tar.gz https://github.com/bats-core/bats-assert/archive/refs/tags/v2.0.0.tar.gz
    tar -xzf /tmp/bats-assert.tar.gz -C /tmp
    mv /tmp/bats-assert-2.0.0 $VKPR_HOME/bats/bats-assert
    # bats-file
    curl -sL -o /tmp/bats-file.tar.gz https://github.com/bats-core/bats-file/archive/refs/tags/v0.3.0.tar.gz
    tar -xzf /tmp/bats-file.tar.gz -C /tmp
    mv /tmp/bats-file-0.3.0 $VKPR_HOME/bats/bats-file
    echo "Bats add-ons installed"
  fi
}

createPackagesFiles() {
  cp $(dirname "$0")/utils/global-values.yaml $VKPR_HOME
  ##Workaround to cp command with regex
  #More details: https://www.oreilly.com/library/view/bash-quick-start/9781789538830/2609b05c-60fa-443d-bb5f-d5cd7626374f.xhtml
  shopt -s extglob
  eval 'cp --update $(dirname "$0")/utils/!(dependencies.sh|!(*.sh)) $VKPR_SCRIPTS'
}