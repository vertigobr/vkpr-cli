#!/usr/bin/env bash

validateInfraTraefik(){
  if $(validateBool $1); then
    return
  else
    error "The value used for VKPR_ENV_TRAEFIK "$VKPR_ENV_TRAEFIK" is invalid:  the VKPR_ENV_TRAEFIK must consist of a boolean value."
    exit
  fi
}

validateInfraHTTP(){
  if $(validatePort $1); then
    return
  else
    error "The value used for VKPR_ENV_HTTP_PORT "$VKPR_ENV_HTTP_PORT" is invalid:  the VKPR_ENV_HTTP_PORT must consist of alphanumeric  characters, (e.g. '8000', regex used for validation is '^([1-9]{1}[0-9]{3})$')"
    exit
  fi
}

validateInfraHTTPS(){
  if $(validatePort $1); then
    return
  else
    error "The value used for VKPR_ENV_HTTPS_PORT "$VKPR_ENV_HTTPS_PORT" is invalid:  the VKPR_ENV_HTTPS_PORT must consist of alphanumeric  characters, (e.g. '8001', regex used for validation is '^([1-9]{1}[0-9]{3})$'"
    exit
  fi
}

validateInfraNodes(){
  if $(validateNumber $1); then
    return
  else
    error "The value used for VKPR_ENV_K3D_AGENTS "$VKPR_ENV_K3D_AGENTS" is invalid: VKPR_ENV_K3D_AGENTS must consist of alphanumeric characters, (e.g. '1', regex used for validation is ^([0-9])$."
    exit
  fi
}
