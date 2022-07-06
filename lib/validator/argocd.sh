#!/bin/bash

# -----------------------------------------------------------------------------
# Argocd validators
# -----------------------------------------------------------------------------

validateArgoDomain (){
  if  $(validateDomain $1); then
    return
  else
    error "Please correctly enter the domain to be used "
    exit
  fi
}

validateArgoSecure(){
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will use HTTPS"
    exit
  fi
}

validateArgoHa (){
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will have High Availability "
    exit
  fi
}

validateArgoNamespace (){
  if [[ "$1" =~ ^([A-Za-z0-9-]+)$ ]]; then
    return
  else
    error "It was not possible to identify the namespace"
    exit
  fi 
}

validateArgoIngressClassName (){
  if [[ "$1" =~ ^([a-z]+)$ ]]; then
    return
  else
    error "Please correctly enter the ingress class name"
    exit
  fi 
}

validateArgoMetrics (){
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will have metrics"
    exit
  fi
}

validateArgoSsl (){
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will use SSL"
    exit
  fi
}

validateArgoSslCrt (){
  if $(validatePath $1); then
    return
  else
    error "Invalid path for SSL .crt file"
    exit
  fi
}

validateArgoSslKey (){
  if $(validatePath $1); then
    return
  else
    error "Invalid path for SSL .key file"
    exit
  fi
}
validateArgoSecretName(){
  if [[ $1 =~ ^([A-Za-z0-9-])$ ]]; then
    return
  else
    error "Please correctly enter the argocd secret name"
    exit
  fi  
}