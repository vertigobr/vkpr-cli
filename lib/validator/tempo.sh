#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Tempo validators
# -----------------------------------------------------------------------------

validateTempoDomain (){
    if  $(validateDomain $1); then
        return
    else
        error "The value used for VKPR_ENV_GLOBAL_DOMAIN \"$1\" is invalid: the VKPR_ENV_GLOBAL_DOMAIN must consist of a lower case alphanumeric  characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example-vkpr.com', regex used for validation is ^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9].)+([a-zA-Z]{2,})|localhost$)"
        exit
    fi
}

validateTempoSecure (){
    if $(validateBool $1); then
        return
    else
        error "The value used for VKPR_ENV_GLOBAL_SECURE \"$1\" is invalid: the VKPR_ENV_GLOBAL_SECURE must consist of a boolean value."
        exit
    fi
}

validateTempoMetrics (){
    if $(validateBool $1); then
        return
    else
        error "The value used for VKPR_ENV_TEMPO_METRICS \"$1\" is invalid: the VKPR_ENV_TEMPO_METRICS must consist of a boolean value."
        exit
    fi
}


validateTempoIngressClassName (){
    if [[ "$1" =~ ^([a-z]+)$ ]]; then
       return
    else
        error "The value used for VKPR_ENV_TEMPO_INGRESS_CLASS_NAME \"$1\" is invalid: VKPR_ENV_TEMPO_INGRESS_CLASS_NAME must consist of lowercase alphanumeric characters, (e.g. 'nginx', regex used for validation is ^([a-z]+)$)"
        exit
    fi
}

validateTempoNamespace (){
    if $(validateNamespace $1); then
        return
    else
        error "The value used for VKPR_ENV_TEMPO_NAMESPACE \"$1\" is invalid: VKPR_ENV_TEMPO_NAMESPACE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'jaeger', regex used for validation is ^([A-Za-z0-9-]+)$)"
        exit
    fi
}

validateTempoPersistance (){
    if $(validateBool $1); then
        return
    else
        error "The value used for VKPR_ENV_TEMPO_PERSISTANCE \"$1\" is invalid: the VKPR_ENV_TEMPO_PERSISTANCE must consist of a boolean value."
        exit
    fi
}


validateTempoSsl (){
    if $(validateBool $1); then
        return
    else
        error "The value used for VKPR_ENV_TEMPO_SSL \"$1\" is invalid: the VKPR_ENV_TEMPO_SSL must consist of a boolean value."
        exit
    fi
}

validateTempoSslCrtPath (){
    if $(validatePath $1); then
        return
    else
        error "The value used for VKPR_ENV_TEMPO_CERTIFICATE \"$1\" is invalid: VKPR_ENV_TEMPO_CERTIFICATE must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. '/tmp/certificate.crt', regex used for validation is ^(\/[^\/]+){1,}\/?$')"
        exit
    fi
}

validateTempoSslKeyPath (){
    if $(validatePath $1); then
        return
    else
        error "The value used for VKPR_ENV_TEMPO_KEY \"$1\" is invalid: VKPR_ENV_TEMPO_KEY must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. '/tmp/certificate.key', regex used for validation is ^(\/[^\/]+){1,}\/?$')"
        exit
    fi
}
