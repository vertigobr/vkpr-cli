#!/bin/bash

runFormula() {
  info "VKPR initialization"
  echo "=============================="
  local VKPR_HOME=~/.vkpr

  mkdir -p $VKPR_HOME/bin
  mkdir -p $VKPR_HOME/config
  mkdir -p $VKPR_HOME/bats

  installArkade
  installOkteto
  installDeck
  installHelm
  #Versions from ./utils/dependencies.sh or latest as default
  validateKubectlVersion
  installTool "kubectl" "$VKPR_TOOLS_KUBECTL"
  validateK3DVersion
  installTool "k3d" "$VKPR_TOOLS_K3D"
  validateJQVersion
  installTool "jq" "$VKPR_TOOLS_JQ"
  validateYQVersion
  installTool "yq" "$VKPR_TOOLS_YQ"

  installBats
}

installArkade() {
  if [[ -f "$VKPR_ARKADE" ]]; then
    warn "Alex Ellis' arkade already installed. Skipping..."
  else
    notice "Installing arkade..."
    # patches download script in order to change BINLOCATION
    curl -sLS https://get.arkade.dev > /tmp/arkinst0.sh
    sed "s/^export BINLOCATION=.*/export BINLOCATION=~\/\.vkpr\/bin/g" /tmp/arkinst0.sh > /tmp/arkinst.sh
    chmod +x /tmp/arkinst.sh
    rm /tmp/arkinst0.sh
    /tmp/arkinst.sh 2> /dev/null
  fi
}

installOkteto() {
  if [[ -f "$VKPR_OKTETO" ]]; then
    warn "Okteto already installed. Skipping..."
  else
    notice "Installing Okteto..."
    # patches download script in order to change BINLOCATION
    curl https://get.okteto.com -sSfL -o /tmp/okteto0.sh
    sed 's|\/usr\/local\/bin|~\/\.vkpr\/bin|g ; 59,71s/^/#/' /tmp/okteto0.sh > /tmp/okteto.sh
    chmod +x /tmp/okteto.sh
    rm /tmp/okteto0.sh
    /tmp/okteto.sh 2> /dev/null
  fi
}

installHelm() {
  notice "Installing Helm..."
  # patches download script in order to change BINLOCATION
  curl -fsSL -o /tmp/get_helm0.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  sed 's|\/usr\/local\/bin|$\HOME/\.vkpr\/bin|g ; s/USE_SUDO:="true"/USE_SUDO:="false"/' /tmp/get_helm0.sh > /tmp/get_helm.sh
  chmod +x /tmp/get_helm.sh
  rm /tmp/get_helm0.sh
  /tmp/get_helm.sh 2> /dev/null
}

##Install tool using arkade and get tools version from ./utils/dependencies.sh or latest as default
installTool() {
  local toolName=$1
  local toolVersion=$2
  if [[ -f "$VKPR_HOME/bin/$toolName" ]]; then
    warn "Tool $toolName already installed. Skipping."
  else
    info "Installing $toolName@${toolVersion:-latest} using arkade..."
    $VKPR_HOME/bin/arkade get "$toolName@$toolVersion" --stash=true > /dev/null
    mv "$HOME/.arkade/bin/$toolName" $VKPR_HOME/bin
    info "$toolName@${toolVersion:-latest} installed!"
  fi
}

#installGlab() {
#  if [[ -f "$VKPR_GLAB" ]]; then
#    warn "Glab already installed. Skipping..."
#  else
#    notice "Installing Glab..."
#    curl -sLS https://j.mp/glab-cli > /tmp/glab.sh
#    chmod +x /tmp/glab.sh
#    /tmp/glab.sh $VKPR_HOME/bin
#  fi
#}

installBats(){
  if [[ -f "$VKPR_HOME/bats/bin/bats" ]]; then
    warn "Bats already installed. Skipping."
  else
    notice "intalling Bats..."
    mkdir -p /tmp/bats
    # bats-core
    curl -sL -o /tmp/bats-core.tar.gz https://github.com/bats-core/bats-core/archive/refs/tags/v1.4.1.tar.gz
    tar -xzf /tmp/bats-core.tar.gz -C /tmp
    mv /tmp/bats-core-1.4.1 /tmp/bats-core
    /tmp/bats-core/install.sh $VKPR_HOME/bats
    rm -rf /tmp/bats-core

    notice "intalling bats add-ons..."
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
    info "Bats add-ons installed"
  fi
}

installDeck() {
  if [[ -f "$VKPR_DECK" ]]; then
    echoColor "yellow" "decK already installed. Skipping..."
  else
    echoColor "blue" "Installing decK..."
    # patches download script in order to change BINLOCATION
    curl -sL https://github.com/kong/deck/releases/download/v"${VKPR_TOOLS_DECK}"/deck_"${VKPR_TOOLS_DECK}"_linux_amd64.tar.gz -o /tmp/deck.tar.gz
    tar -xf /tmp/deck.tar.gz -C /tmp
    cp /tmp/deck ~/.vkpr/bin
    info "Deck installed!"
  fi
}

