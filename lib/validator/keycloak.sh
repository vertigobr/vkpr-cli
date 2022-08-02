#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Keycloak validators
# -----------------------------------------------------------------------------

validateKeycloakDomain (){
  if $(validateDomain $1); then
    return
  else
    error "It was not possible to identify if the application will have High Availability "
    exit
  fi
}

validateKeycloakSecure (){
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will use HTTPS"
    exit
  fi
}

validateKeycloakHa () {
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will have High Availability "
    exit
  fi
}

validateKeycloakAdminUser (){
  if [[ "$1" =~ ^([A-Za-z0-9-]{1,}) ]]; then
    return
  else
    error "Invalid input to Super Admin username"
    exit
  fi
}

validateKeycloakAdminPwd (){
  if $(validatePwd $1); then
    return
  else
    error "Invalid Super Admin password"
    exit
  fi
}

validateKeycloakIngresClassName (){
  if [[ "$1" =~ ^([a-z]+)$ ]]; then
    return
  else
    error "Please correctly enter the ingress class name"
    exit
  fi
}

validateKeycloakNamespace (){
  if $(validateNamespace $1); then
    return
  else
    error "It was not possible to identify the namespace"
    exit
  fi
}

validateKeycloakSsl (){
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will use SSL"
    exit
  fi
}

validateKeycloakCrt (){
  if $(validatePath $1); then
    return
  else
    error "Invalid path for SSL .crt file"
    exit
  fi
}

validateKeycloakKey (){
  if $(validatePath $1); then
    return
  else
    error "Invalid path for SSL .key file"
    exit
  fi
}

validateKeycloakMetrics (){
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will have metrics"
    exit
  fi
}
