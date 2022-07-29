#!/bin/bash

# -----------------------------------------------------------------------------
# Whoami validators
# -----------------------------------------------------------------------------

validateWhoamiSecure(){
  if $(validateBool $1); then
    return 
  else
    error "Specifies if the application will have HTTPS."
    exit
  fi
}

validateWhoamiDomain (){
  if  $(validateDomain $1); then
    return
  else
    error "Please correctly enter the domain to be used "
    exit
  fi
}

validateWhoamiSecure (){
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will use HTTPS"
    exit
  fi
}

validateWhoamiSsl (){
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will use SSL"
    exit
  fi
}

validateWhoamiSslCrtPath (){
  if $(validatePath $1); then
    return
  else
    error "Invalid path for SSL .crt file"
    exit
  fi
}

validateWhoamiSslKeyPath (){
  if $(validatePath $1); then
    return
  else
    error "Invalid path for SSL .key file"
    exit
  fi
}

