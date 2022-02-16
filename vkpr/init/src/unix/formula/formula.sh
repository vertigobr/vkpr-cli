#!/bin/sh

#
# Downloads tools and other CLIs used transparently
#
# Trying to use `arkade` when possible
#
# Requires: curl

runFormula() {
  echoColor "green" "VKPR initialization"
  echo "=============================="
  local VKPR_HOME=~/.vkpr
  local VKPR_SCRIPTS=$VKPR_HOME/src
  
  mkdir -p $VKPR_HOME/bin
  mkdir -p $VKPR_HOME/config
  mkdir -p $VKPR_HOME/bats
  mkdir -p $VKPR_HOME/src

  installArkade
  installGlab
  #Versions from ./utils/dependencies.sh or latest as default
  validateKubectlVersion
  installTool "kubectl" $VKPR_TOOLS_KUBECTL
  validateHelmVersion
  installTool "helm" $VKPR_TOOLS_HELM
  validateK3DVersion
  installTool "k3d" $VKPR_TOOLS_K3D
  validateJQVersion
  installTool "jq" $VKPR_TOOLS_JQ
  validateYQVersion
  installTool "yq" $VKPR_TOOLS_YQ
  # validateK9SVersion
  # installTool "k9s" $VKPR_TOOLS_K9S

  installGlobals 
  installBats

} 

installArkade() {
  if [[ -f "$VKPR_ARKADE" ]]; then
    echoColor "yellow" "Alex Ellis' arkade already installed. Skipping..."
  else
    echoColor "blue" "Installing arkade..."
    # patches download script in order to change BINLOCATION
    curl -sLS https://get.arkade.dev > /tmp/arkinst0.sh
    sed "s/^export BINLOCATION=.*/export BINLOCATION=~\/\.vkpr\/bin/g" /tmp/arkinst0.sh > /tmp/arkinst.sh
    chmod +x /tmp/arkinst.sh
    rm /tmp/arkinst0.sh
    /tmp/arkinst.sh 2> /dev/null
  fi
}

##Install tool using arkade and get tools version from ./utils/dependencies.sh or latest as default
installTool() {
  local toolName=$1
  local toolVersion=$2
  if [[ -f "$VKPR_HOME/bin/$toolName" ]]; then
    echoColor "yellow" "Tool $toolName already installed. Skipping."
  else
    echoColor "green" "Installing $toolName@${toolVersion:-latest} using arkade..."
    $VKPR_HOME/bin/arkade get "$toolName@$toolVersion" --stash=true > /dev/null
    mv "$HOME/.arkade/bin/$toolName" $VKPR_HOME/bin
    echoColor "green" "$toolName@${toolVersion:-latest} installed!"
  fi
}

installGlab() {
  if [[ -f "$VKPR_GLAB" ]]; then
    echoColor "yellow" "Glab already installed. Skipping..."
  else
    echoColor "blue" "Installing Glab..."
    curl -sLS https://j.mp/glab-cli > /tmp/glab.sh
    chmod +x /tmp/glab.sh
    /tmp/glab.sh $VKPR_HOME/bin
  fi
}

installGlobals() {
  ##Workaround to cp command with regex
  #More details: https://www.oreilly.com/library/view/bash-quick-start/9781789538830/2609b05c-60fa-443d-bb5f-d5cd7626374f.xhtml
  shopt -s extglob
  eval 'cp $(dirname "$0")/utils/!(dependencies.sh|!(*.sh)) $VKPR_SCRIPTS'
}

installBats(){
  if [[ -f "$VKPR_HOME/bats/bin/bats" ]]; then
    echoColor "yellow" "Bats already installed. Skipping."
  else
    echoColor "blue" "intalling Bats..."
    mkdir -p /tmp/bats
    # bats-core
    curl -sL -o /tmp/bats-core.tar.gz https://github.com/bats-core/bats-core/archive/refs/tags/v1.4.1.tar.gz
    tar -xzf /tmp/bats-core.tar.gz -C /tmp
    mv /tmp/bats-core-1.4.1 /tmp/bats-core
    /tmp/bats-core/install.sh $VKPR_HOME/bats
    rm -r --force /tmp/bats-core

    echoColor "blue" "intalling bats add-ons..."
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
    echoColor "green" "Bats add-ons installed"
  fi
}
