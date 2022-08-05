#!/bin/bash

# -----------------------------------------------------------------------------
# DevPortal validators
# -----------------------------------------------------------------------------

validateDevportalSecure (){
  if $(validateBool $1); then
      return
  else
      error "The value used for VKPR_ENV_GLOBAL_SECURE "$VKPR_ENV_GLOBAL_SECURE" is invalid:  the VKPR_ENV_GLOBAL_SECURE must consist of a boolean value."
      exit
  fi
}

validateDevportalDomain (){
  if  $(validateDomain $1); then
      return
  else
      error "The value used for VKPR_ENV_DEVPORTAL_DOMAIN "$VKPR_ENV_DEVPORTAL_DOMAIN" is invalid:  the VKPR_ENV_DEVPORTAL_DOMAIN must consist of a lower case alphanumeric  characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'devportal.localhost', regex used for validation is '^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9].)+([a-zA-Z]{2,})|localhost$'). "
      exit
  fi
}

validateDevportalIngressClassName (){
  if [[ "$1" =~ ^([a-z]+)$ ]]; then
      return
  else
      error "The value used for VKPR_ENV_DEVPORTAL_INGRESS_CLASS_NAME "$VKPR_ENV_DEVPORTAL_INGRESS_CLASS_NAME" is invalid: VKPR_ENV_DEVPORTAL_INGRESS_CLASS_NAME must consist of lowercase, (e.g. 'devportal', regex used for validation is ^([a-z]+)$')."
      exit
  fi 
}

validateDevportalNamespace (){
  if $(validateNamespace $1); then
      return
  else
      error "The value used for VKPR_ENV_DEVPORTAL_NAMESPACE "$VKPR_ENV_DEVPORTAL_NAMESPACE" is invalid: VKPR_ENV_DEVPORTAL_NAMESPACE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'devportal', regex used for validation is ^([A-Za-z0-9-]+)$')"
      exit
  fi 
}
