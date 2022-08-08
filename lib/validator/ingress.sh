#!/usr/bin/env bash

validateIngressMetrics() {
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will have metrics"
    exit
  fi
}

validateIngressNamespace(){
  if $(validateNamespace "$1"); then
    return
  else
    error "It was not possible to identify the namespace."
    exit
  fi
}

validateIngressSSL(){
  if $(validateBool $1); then
    return
  else
    error "Specifies if the application will have Ingress SSL."
    exit
  fi
}

validateIngressCertificate(){
  if $(validatePath $1); then
    return
  else
    error "Invalid path for Ingress SSL .crt file."
    exit
  fi
}

validateIngressKey(){
  if $(validatePath $1); then
    return
  else
    error "Invalid path for Ingress SSL .key file."
    exit
  fi
}
