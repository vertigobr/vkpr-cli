#!/bin/bash

# -----------------------------------------------------------------------------
# Loki validators
# -----------------------------------------------------------------------------

validateLokiMetrics (){
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will have metrics"
    exit
  fi
}

validateLokiPersistence (){
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will have persistance"
    exit
  fi   
}

validateLokiNamespace (){
  if $(validateNamespace $1); then
      return
  else
    error "It was not possible to identify the namespace"
    exit
  fi 
}
