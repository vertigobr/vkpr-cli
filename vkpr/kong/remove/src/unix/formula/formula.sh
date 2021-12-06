#!/bin/sh

runFormula() {
  helm uninstall kong -n kong
  kubectl delete ns kong
}
