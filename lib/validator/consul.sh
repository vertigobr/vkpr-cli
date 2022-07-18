#!/bin/bash

# -----------------------------------------------------------------------------
# Consul validators
# -----------------------------------------------------------------------------

validateConsulDomain(){
  if  $(validateDomain $1); then
    return
  else
    error "Please correctly enter the domain to be used "
    exit
  fi
}

validateConsulSecure(){
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will use HTTPS"
    exit
  fi
}

validateConsulIngressClassName(){
  if [[ "$1" =~ ^([a-z]+)$ ]]; then
   return
  else
    error "Please correctly enter the ingress class name"
    exit
  fi 
}

validateConsulNamespace(){
  if [[ "$1" =~ ^([A-Za-z0-9-]+)$ ]]; then
    return
  else
    error "It was not possible to identify the namespace"
    exit
  fi 
}

validateConsulSsl(){
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will use SSL"
    exit
  fi
}

validateConsulSslCrtPath (){
  if $(validatePath $1); then
    return
  else
    error "Invalid path for SSL .crt file"
    exit
  fi
}

validateConsulSslKeyPath(){
  if $(validatePath $1); then
    return
  else
    error "Invalid path for SSL .key file"
    exit
  fi
}
