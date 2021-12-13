#!/bin/bash

runFormula() {
  $VKPR_HELM uninstall consul -n $VKPR_K8S_NAMESPACE
}
