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
  mkdir -p $VKPR_HOME/certs

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
  installBats
  installeksctl
}

installeksctl(){
 curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
 sudo mv /tmp/eksctl /usr/local/bin
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
    unzip -o -q /tmp/awscliv2.zip -d /tmp
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
    info "Installing $toolName $toolVersion using arkade..."
    $VKPR_HOME/bin/arkade get $toolName --version=$toolVersion --path="$VKPR_HOME/bin" > /dev/null
    info "$toolName $toolVersion installed!"
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
    sed 's|\/usr\/local\/bin|$\HOME/\.vkpr\/bin|g' /tmp/get_helm0.sh > /tmp/get_helm.sh
    chmod +x /tmp/get_helm.sh
    rm /tmp/get_helm0.sh
    /tmp/get_helm.sh --version $VKPR_TOOLS_HELM --no-sudo > /dev/null
    rm /tmp/get_helm.sh
    info "Helm installed!"
  fi
  installHelmDiff
}

installHelmDiff (){
  if [[ -f "$VKPR_HELM" ]]; then
    if [[ -f "$HOME/.local/share/helm/plugins/helm-diff/README.md" ]]; then
      notice "Helm diff already installed. Skipping..."
    else
      info "Installing Helm diff..."
      $VKPR_HELM plugin install https://github.com/databus23/helm-diff > /dev/null
      info "Helm diff installed!"
    fi
  else
    warn "Helm not installed."
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

installBats(){
  if [[ -f "$VKPR_HOME/bats/bin/bats" ]]; then
    notice "Bats already installed. Skipping."
  else
    info "intalling Bats..."
    mkdir -p /tmp/bats
    # bats-core
    # docs: https://github.com/bats-core/bats-core
    curl -sL -o /tmp/bats-core.tar.gz https://github.com/bats-core/bats-core/archive/refs/tags/v$VKPR_TOOLS_BATS_CORE.tar.gz
    tar -xzf /tmp/bats-core.tar.gz -C /tmp
    mv /tmp/bats-core-$VKPR_TOOLS_BATS_CORE /tmp/bats-core
    /tmp/bats-core/install.sh $VKPR_HOME/bats
    rm -rf /tmp/bats-core

    warn "intalling Bats support..."
    # bats-support
    # docs: https://github.com/bats-core/bats-support
    curl -sL -o /tmp/bats-support.tar.gz https://github.com/bats-core/bats-support/archive/refs/tags/v$VKPR_TOOLS_BATS_SUPPORT.tar.gz
    tar -xzf /tmp/bats-support.tar.gz -C /tmp
    mv /tmp/bats-support-$VKPR_TOOLS_BATS_SUPPORT $VKPR_HOME/bats/bats-support

    warn "intalling Bats assert..."
    # bats-assert
    # docs: https://github.com/bats-core/bats-assert
    curl -sL -o /tmp/bats-assert.tar.gz https://github.com/bats-core/bats-assert/archive/refs/tags/v$VKPR_TOOLS_BATS_ASSERT.tar.gz
    tar -xzf /tmp/bats-assert.tar.gz -C /tmp
    mv /tmp/bats-assert-$VKPR_TOOLS_BATS_ASSERT $VKPR_HOME/bats/bats-assert

    warn "intalling Bats file..."
    # bats-file
    # docs: https://github.com/bats-core/bats-file
    curl -sL -o /tmp/bats-file.tar.gz https://github.com/bats-core/bats-file/archive/refs/tags/v$VKPR_TOOLS_BATS_FILE.tar.gz
    tar -xzf /tmp/bats-file.tar.gz -C /tmp
    mv /tmp/bats-file-$VKPR_TOOLS_BATS_FILE $VKPR_HOME/bats/bats-file

    warn "intalling Bats detik..."
    # bats-detik
    # docs: https://github.com/bats-core/bats-detik
    mkdir -p $VKPR_HOME/bats/bats-detik/src

    curl -s https://raw.githubusercontent.com/bats-core/bats-detik/v$VKPR_TOOLS_BATS_DEKIT/lib/detik.bash > $VKPR_HOME/bats/bats-detik/src/detik.bash
    curl -s https://raw.githubusercontent.com/bats-core/bats-detik/v$VKPR_TOOLS_BATS_DEKIT/lib/utils.bash > $VKPR_HOME/bats/bats-detik/src/utils.bash
    curl -s https://raw.githubusercontent.com/bats-core/bats-detik/v$VKPR_TOOLS_BATS_DEKIT/lib/linter.bash > $VKPR_HOME/bats/bats-detik/src/linter.bash
    cat > $VKPR_HOME/bats/bats-detik/load.bash.tmp <<EOF
source "$\(dirname "$\{BASH_SOURCE[0]}")/src/utils.bash"
source "$\(dirname "$\{BASH_SOURCE[0]}")/src/linter.bash"
source "$\(dirname "$\{BASH_SOURCE[0]}")/src/detik.bash"
EOF

    sed 's/\\//g' $VKPR_HOME/bats/bats-detik/load.bash.tmp > $VKPR_HOME/bats/bats-detik/load.bash
    chmod +x $VKPR_HOME/bats/bats-detik/load.bash

    info "Bats installed!"
  fi

}
