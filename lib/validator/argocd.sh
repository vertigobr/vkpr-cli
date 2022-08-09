#!/bin/bash

# -----------------------------------------------------------------------------
# Argocd validators
# -----------------------------------------------------------------------------

validateArgoDomain (){
  if  $(validateDomain $1); then
    return
  else
    error "The value used for DOMAIN \"$1\" is invalid:  the DOMAIN must consist of a lower case alphanumeric  characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example-vkpr.com', regex used for validation is '^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9].)+([a-zA-Z]{2,})|localhost$')"
    exit
  fi
}

validateArgoSecure(){
  if $(validateBool $1); then
    return
  else
    error "The value used for GLOBAL_SECURE \"$1\" is invalid:  the GLOBAL_SECURE must consist of a boolean value."
    exit
  fi
}

validateArgoHa (){
  if $(validateBool $1); then
    return
  else
    error "The value used for ARGO_HA \"$1\" is invalid:  the ARGO_HA must consist of a boolean value."
    exit
  fi
}

validateArgoNamespace (){
  if [[ "$1" =~ ^([A-Za-z0-9-]+)$ ]]; then
    return
  else
    error "The value used for ARGO_NAMESPACE \"$1\" is invalid: ARGO_NAMESPACE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'argocd', regex used for validation is ^([A-Za-z0-9-]+)$')"
    exit
  fi 
}

validateArgoIngressClassName (){
  if [[ "$1" =~ ^([a-z]+)$ ]]; then
    return
  else
    error "The value used for ARGOCD_INGRESS_CLASS_NAME \"$1\" is invalid: ARGOCD_INGRESS_CLASS_NAME must consist of lowercase alphanumeric characters, (e.g. 'argo', regex used for validation is ^([a-z]+)$')"
    exit
  fi 
}

validateArgoMetrics (){
  if $(validateBool $1); then
    return
  else
    error "The value used for ARGOCD_METRICS \"$1\" is invalid:  the ARGOCD_METRICS must consist of a boolean value."
    exit
  fi
}

validateArgoSsl (){
  if $(validateBool $1); then
    return
  else
    error "The value used for ARGOCD_SLL \"$1\" is invalid:  the ARGOCD_SSL must consist of a boolean value."
    exit
  fi
}

validateArgoSslCrt (){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_ARGOCD_SSL_CERTIFICATE \"$1\" is invalid: VKPR_ENV_ARGOCD_SSL_CERTIFICATE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'vkpr/argocd/certificate.crt', regex used for validation is ^(\/[^\/]+){1,}\/?$')"
    exit
  fi
}

validateArgoSslKey (){
  if $(validatePath $1); then
    return
  else
    error "The value used for VKPR_ENV_ARGOCD_SSL_KEY \"$1\" is invalid: VKPR_ENV_ARGOCD_SSL_KEY must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'vkpr/argocd/certificate.key', regex used for validation is ^(\/[^\/]+){1,}\/?$')"
    exit
  fi
}
validateArgoSecretName(){
  if [[ $1 =~ ^([A-Za-z0-9-])$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_ARGOCD_SSL_SECRET \"$1\" is invalid: VKPR_ENV_ARGOCD_SSL_SECRET must consist of lowercase, uppercase or alphanumeric characters, (e.g. 'argocd', regex used for validation is ^([A-Za-z0-9-])$')"
    exit
  fi  
}