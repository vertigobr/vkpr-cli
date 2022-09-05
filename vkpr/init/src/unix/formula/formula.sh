#!/usr/bin/env bash

# shellcheck source=src/util.sh
source "$(dirname "$0")"/utils/dependencies.sh

runFormula() {
  boldInfo "VKPR initialization"
  bold "=============================="
  local VKPR_HOME=~/.vkpr

  mkdir -p $VKPR_HOME/bin
  mkdir -p $VKPR_HOME/config
  mkdir -p $VKPR_HOME/bats

  installArkade
  validateKubectlVersion
  installTool "kubectl" "$VKPR_TOOLS_KUBECTL"
  validateK3DVersion
  installTool "k3d" "$VKPR_TOOLS_K3D"
  validateJQVersion
  installTool "jq" "$VKPR_TOOLS_JQ"
  validateYQVersion
  installTool "yq" "$VKPR_TOOLS_YQ"

  installAWS
  installOkteto
  installDeck
  installHelm
}

installArkade() {
  if [[ -f "$VKPR_ARKADE" ]]; then
    notice "Alex Ellis' arkade already installed. Skipping..."
  else
    info "Installing arkade..."
    # patches download script in order to change BINLOCATION
    curl -sLS https://get.arkade.dev > /tmp/arkinst0.sh
    sed "s/^export BINLOCATION=.*/export BINLOCATION=~\/\.vkpr\/bin/g" /tmp/arkinst0.sh > /tmp/arkinst.sh
    chmod +x /tmp/arkinst.sh
    rm /tmp/arkinst0.sh
    /tmp/arkinst.sh 2> /dev/null
  fi
}

installAWS() {
  if [[ -f "$VKPR_AWS" ]]; then
    notice "AWS already installed. Skipping..."
  else
    info "Installing AWS..."
    # patches download script in order to change BINLOCATION
    curl -sSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip
    unzip -q /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install -i ~/.vkpr/bin -b ~/.vkpr/bin --update
  fi
}

##Install tool using arkade and get tools version from ./utils/dependencies.sh or latest as default
installTool() {
  local toolName=$1
  local toolVersion=$2
  if [[ -f "$VKPR_HOME/bin/$toolName" ]]; then
    notice "Tool $toolName already installed. Skipping."
  else
    info "Installing $toolName@${toolVersion:-latest} using arkade..."
    $VKPR_HOME/bin/arkade get "$toolName@$toolVersion" --stash=true > /dev/null
    mv "$HOME/.arkade/bin/$toolName" $VKPR_HOME/bin
    info "$toolName@${toolVersion:-latest} installed!"
  fi
}

installOkteto() {
  if [[ -f "$VKPR_OKTETO" ]]; then
    notice "Okteto already installed. Skipping..."
  else
    info "Installing Okteto..."
    # patches download script in order to change BINLOCATION
    curl https://get.okteto.com -sSfL -o /tmp/okteto0.sh
    sed 's|\/usr\/local\/bin|~\/\.vkpr\/bin|g ; 59,71s/^/#/' /tmp/okteto0.sh > /tmp/okteto.sh
    chmod +x /tmp/okteto.sh
    rm /tmp/okteto0.sh
    /tmp/okteto.sh 2> /dev/null
  fi
}

installHelm() {
  if [[ -f "$VKPR_HELM" ]]; then
    notice "Helm already installed. Skipping..."
  else
    info "Installing Helm..."
    # patches download script in order to change BINLOCATION
    curl -fsSL -o /tmp/get_helm0.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    sed 's|\/usr\/local\/bin|$\HOME/\.vkpr\/bin|g; 251,259s/^/#/; 325s/^/#/' /tmp/get_helm0.sh > /tmp/get_helm.sh
    chmod +x /tmp/get_helm.sh
    rm /tmp/get_helm0.sh
    /tmp/get_helm.sh --version $VKPR_TOOLS_HELM --no-sudo 2> /dev/null
  fi
}

installDeck() {
  if [[ -f "$VKPR_DECK" ]]; then
    notice "decK already installed. Skipping..."
  else
    info "Installing decK..."
    # patches download script in order to change BINLOCATION
    curl -sL https://github.com/kong/deck/releases/download/v"${VKPR_TOOLS_DECK}"/deck_"${VKPR_TOOLS_DECK}"_linux_amd64.tar.gz -o /tmp/deck.tar.gz
    tar -xf /tmp/deck.tar.gz -C /tmp
    cp /tmp/deck ~/.vkpr/bin
    info "Deck installed!"
  fi
}
