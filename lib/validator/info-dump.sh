#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Info Dump validators
# -----------------------------------------------------------------------------


validateInfoDumpPath (){
    if $(validatePath $1); then
        return
    else
        error "The value used for APPLICATION_PATH \"$1\" is invalid: APPLICATION_PATH must consist of lowercase, uppercase and '-' alphanumeric characters, (e.g. '/home/user', regex used for validation is ^(\/[^\/]+){1,}\/?$')"
        exit
    fi
}

validateInfoDumpName(){
  if $(validateNamespace "$1"); then
    return
  else
    error "The value used for APPLICATION_NAME \"$1\" is invalid: APPLICATION_NAME must consist of lowercase and '-' alphanumeric characters, (e.g. 'ingress', regex used for validation is ^([A-Za-z0-9-]+)$')"
    exit
  fi
}