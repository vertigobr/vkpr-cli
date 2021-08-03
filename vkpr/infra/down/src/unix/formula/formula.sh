#!/bin/sh

runFormula() {
  echo "VKPR local infra stop routine"
  echo "=============================="
  stopCluster
}

stopCluster() {
  # local registry
  if $(k3d cluster list | grep -q "vkpr-local"); then
    k3d cluster delete vkpr-local
  else
    echoColor "red" "Cluster vkpr-local not running, skipping."
  fi
}

echoColor() {
  case $1 in
    red)
      echo "$(printf '\033[31m')$2$(printf '\033[0m')"
      ;;
    green)
      echo "$(printf '\033[32m')$2$(printf '\033[0m')"
      ;;
    yellow)
      echo "$(printf '\033[33m')$2$(printf '\033[0m')"
      ;;
    blue)
      echo "$(printf '\033[34m')$2$(printf '\033[0m')"
      ;;
    cyan)
      echo "$(printf '\033[36m')$2$(printf '\033[0m')"
      ;;
    esac
}
