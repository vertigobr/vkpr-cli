#!/usr/bin/env bash

declare -Agr C=(
  [red]=$(echo -e '\033[31m')
  [green]=$(echo -e '\033[32m')
  [yellow]=$(echo -e '\033[33m')
  [blue]=$(echo -e '\033[34m')
  [cyan]=$(echo -e '\033[36m')
  [bold]=$(echo -e '\033[1m')
  [boldred]=$(echo -e '\033[01;31m')
  [boldgreen]=$(echo -e '\033[01;32m')
  [boldyellow]=$(echo -e '\033[01;33m')
  [boldblue]=$(echo -e '\033[01;34m')
  [boldcyan]=$(echo -e '\033[01;36m')
)

NC=$(echo -e "\e[0m")
readonly NC

export C

log() {
  local TOTERM=${1:-}
  local MESSAGE=${2:-}
  echo -e "${MESSAGE:-}" | (
    if [[ ${TOTERM} == true ]] ; then
      tee -a >&2
    fi
  )
}

bold() { log "true" "${C[bold]}$*${NC}"; }
info() { log "true" "${C[green]}$*${NC}"; }
infoYellow() { log "true" "${C[yellow]}$*${NC}"; }
boldInfo() { log "true" "${C[boldgreen]}$*${NC}"; }
notice() { log "true" "${C[blue]}$*${NC}"; }
boldNotice() { log "true" "${C[boldblue]}$*${NC}"; }
error() { log "true" "${C[red]}$*${NC}"; }
boldError() { log "true" "${C[boldred]}$*${NC}"; }
trace() { log "${LOG_TRACE:-}" "${C[cyan]}$*${NC}"; }
boldTrace() { log "${LOG_TRACE:-}" "${C[boldcyan]}$*${NC}"; }
warn() { log "${LOG_DEBUG:-}" "${C[yellow]}$*${NC}"; }
boldWarn() { log "${LOG_DEBUG:-}" "${C[boldyellow]}$*${NC}"; }
debug() { log "${LOG_DEBUG:-}" "${C[red]}${C[red]}[DEBUG]${NC} $*${NC}"; }
