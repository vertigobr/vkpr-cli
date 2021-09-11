#!/bin/sh

runFormula() {
  echoColor "yellow" "Removendo external-dns..."
  rm -rf $VKPR_HOME/values/external-dns
  helm delete external-dns
}
