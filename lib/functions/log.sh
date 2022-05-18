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

info() { log "${LOG_VERBOSE:-}" "${C[green]}$*${NC}"; }
notice() { log "${LOG_NOTICE:-}" "${C[blue]}$*${NC}"; }
warn() { log "${LOG_WARN:-}" "${C[yellow]}$*${NC}"; }
error() { log "${LOG_ERROR:-}" "${C[red]}$*${NC}"; }
debug() { log "${LOG_DEBUG:-}" "${C[red]}${C[red]}[DEBUG]${NC} $*${NC}"; }