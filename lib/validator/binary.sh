#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Binary validators
# -----------------------------------------------------------------------------

validateKubectlVersion() {
  if [[ ! -f $VKPR_KUBECTL ]] || $VKPR_KUBECTL version | grep -q $VKPR_TOOLS_KUBECTL; then
    return
  else
    rm "$VKPR_KUBECTL"
  fi
}

validateHelmVersion() {
  if [[ ! -f $VKPR_HELM ]] || [[ $($VKPR_HELM version --short | awk -F "+" '{print $1}') = "$VKPR_TOOLS_HELM" ]]; then
    return
  else
    rm "$VKPR_HELM"
  fi
}

validateK3DVersion() {
  if [[ ! -f $VKPR_K3D ]] || [[ $($VKPR_K3D version | awk -F " " '{print $3}' | head -n1) = "$VKPR_TOOLS_K3D" ]]; then
    return
  else
    rm "$VKPR_K3D"
  fi
}

validateJQVersion() {
  if [[ ! -f $VKPR_JQ ]] || [[ $($VKPR_JQ --version) = "$VKPR_TOOLS_JQ" ]]; then
    return
  else
    rm "$VKPR_JQ"
  fi
}

validateYQVersion() {
  if [[ ! -f $VKPR_YQ ]] || [[ $($VKPR_YQ --version | awk -F " " '{print $4}') = "$VKPR_TOOLS_YQ" ]]; then
    return
  else
    rm "$VKPR_YQ"
  fi
}

validateK9SVersion() {
  if [[ ! -f $VKPR_K9S ]] || [[ $($VKPR_K9S version --short | awk -F " " '{print $2}' | head -n1) = "$VKPR_TOOLS_K9S" ]]; then
    return
  else
    rm "$VKPR_K9S"
  fi
}
