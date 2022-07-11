#!/bin/bash

validateInfraTraefik(){
  if $(validateBool $1); then
    return
  else
    error "Enable Traefik by default in Cluster."
    exit
  fi
}

validateInfraHTTP(){
  if $(validatePort $1); then
    return
  else
    error "It was not possible to identify if the application will have HTTP."
    exit
  fi
}

validateInfraHTTPS(){
  if $(validatePort $1); then
    return
  else
    error "It was not possible to identify if the application will have HTTPS."
    exit
  fi
}

validateInfraNodes(){
  if $(validateNumber $1); then
    return
  else
    error "It was not possible to identify if the application will have Nodes."
    exit
  fi
}