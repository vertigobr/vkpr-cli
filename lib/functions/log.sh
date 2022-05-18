#!/bin/bash

declare -Agr C=(
  [red]=$(echo -e '\033[31m')
  [green]=$(echo -e '\033[32m')
  [yellow]=$(echo -e '\033[33m')
  [blue]=$(echo -e '\033[34m')
  [cyan]=$(echo -e '\033[36m')
  [bold]=$(echo -e '\033[1m')
)

NC=$(echo -e "\e[0m")
readonly NC

export C

log() {
  local TOTERM=${1:-}
  local MESSAGE=${2:-}
  echo -e "${MESSAGE:-}" 
}

info() { log "${LOG_VERBOSE:-}" "${C[green]}$${NC}"; }
bold() { log "${LOG_VERBOSE:-}" "${C[bold]}$${NC}"; }
notice() { log "${LOG_NOTICE:-}" "${C[blue]}$${NC}"; }
warn() { log "${LOG_WARN:-}" "${C[yellow]}$${NC}"; }
error() { log "${LOG_ERROR:-}" "${C[red]}$${NC}"; }
debug() { log "${LOG_DEBUG:-}" "${C[red]}${C[red]}[DEBUG]${NC} $*${NC}"; }


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
    bold)
      echo "$(printf '\033[1m')$2$(printf '\033[0m')"
    esac
}