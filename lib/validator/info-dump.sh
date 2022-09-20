#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Info Dump validators
# -----------------------------------------------------------------------------


validateInfoDumpPath (){
    if $(validatePath $1); then
        return
    else
        error "The value used for APLICATION_PATH \"$1\" is invalid: APLICATION_PATH must consist of lowercase and '-' alphanumeric characters, (e.g. '/tmp/certificate.key', regex used for validation is ^(\/[^\/]+){1,}\/?$')"
        exit
    fi
}

validateInfoDumpNamespace(){
  if $(validateNamespace "$1"); then
    return
  else
    error "The value used for APLICATION_NAMESPACE \"$1\" is invalid: APLICATION_NAMESPACE must consist of lowercase and '-' alphanumeric characters, (e.g. 'ingress', regex used for validation is ^([A-Za-z0-9-]+)$')"
    exit
  fi
}

validateInfoDumpName(){
  if $(validateNamespace "$1"); then
    return
  else
    error "The value used for APLICATION_NAME \"$1\" is invalid: APLICATION_NAME must consist of lowercase and '-' alphanumeric characters, (e.g. 'ingress', regex used for validation is ^([A-Za-z0-9-]+)$')"
    exit
  fi
}