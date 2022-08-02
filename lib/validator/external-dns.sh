#!/usr/bin/env bash

validateExternalDNSDomain() {
  if $(validateDomain $1); then
    return
  else
    error "Please correctly enter the domain to be used."
    exit
  fi
}

validateExternalDNSNamespace() {
  if $(validateNamespace "$1"); then
    return
  else
    error "It was not possible to identify the namespace."
    exit
  fi
}

validateExternalDNSMetrics() {
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will have metrics"
    exit
  fi
}
