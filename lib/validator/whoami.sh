#!/bin/bash

validateWhoamiSecure(){
  if $(validateBool $1); then
    return 
  else
    error "Specifies if the application will have HTTPS."
    exit
  fi
}