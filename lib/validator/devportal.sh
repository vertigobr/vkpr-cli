#!/bin/bash

# -----------------------------------------------------------------------------
# DevPortal validators
# -----------------------------------------------------------------------------

validateDevportalSecure (){
  if $(validateBool $1); then
      return
  else
      error "It was not possible to identify if the application will use HTTPS"
      exit
  fi
}

validateDevportalDomain (){
  if  $(validateDomain $1); then
      return
  else
      error "Please correctly enter the domain to be used "
      exit
  fi
}

validateDevportalIngressClassName (){
  if [[ "$1" =~ ^([a-z]+)$ ]]; then
      return
  else
      error "Please correctly enter the ingress class name"
      exit
  fi 
}

validateDevportalNamespace (){
  if $(validateNamespace $1); then
      return
  else
      error "It was not possible to identify the namespace"
      exit
  fi 
}
