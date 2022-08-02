#!/usr/bin/env bash

validateMockServerDomain() {
  if $(validateDomain $1); then
    return
  else
    error "Please correctly enter the domain to be used."
    exit
  fi
}

validateMockServerSecure() {
  if $(validateBool "$1"); then
    return
  else
    error "It was not possible to identify if the application will have HTTPS."
    exit
  fi
}

validateMockServerIngressClassName(){
  if [[ "$1" =~ ^([a-z]+)$ ]]; then
   return
  else
    error "Please correctly enter the ingress class name."
    exit
  fi
}

validateMockServerNamespace(){
  if $(validateNamespace "$1"); then
    return
  else
    error "It was not possible to identify the namespace."
    exit
  fi
}

validateMockServerSSL(){
  if $(validateBool $1); then
    return
  else
    error "Specifies if the application will have MockServer SSL."
    exit
  fi
}

validateMockServerCertificate(){
  if $(validatePath $1); then
    return
  else
    error "Invalid path for MockServer SSL .crt file."
    exit
  fi
}

validateMockServerKey(){
  if $(validatePath $1); then
    return
  else
    error "Invalid path for MockServer SSL .key file."
    exit
  fi
}
