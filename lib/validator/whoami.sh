#!/bin/bash

# -----------------------------------------------------------------------------
# Whoami validators
# -----------------------------------------------------------------------------

validateWhoamiSecure(){
  echo "$1"
  if $(validateBool $1); then
    return 
  else
    error "Specifies if the application will have HTTPS."
    exit
  fi
}

validateWhoamiDomain (){
  echo "$1"
  if  $(validateDomain $1); then
    return
  else
    error "Please correctly enter the domain to be used "
    exit
  fi
}

validateWhoamiSecure (){
  echo "$1"
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will use HTTPS"
    exit
  fi
}

validateWhoamiSsl (){
  echo "$1"
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will use SSL"
    exit
  fi
}

validateWhoamiSslCrtPath (){
  echo "$1"
  if $(validatePath $1); then
    return
  else
    error "Invalid path for SSL .crt file"
    exit
  fi
}

validateWhoamiSslKeyPath (){
  echo "$1"
  if $(validatePath $1); then
    return
  else
    error "Invalid path for SSL .key file"
    exit
  fi
}

