#!/bin/sh

runFormula() {
  echo "VKPR Ingress install"
  $VKPR_HOME/bin/arkade install ingress-nginx
}
