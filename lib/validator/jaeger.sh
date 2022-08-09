#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Jaeger validators
# -----------------------------------------------------------------------------

validateJaegerDomain (){
    if  $(validateDomain $1); then
        return
    else
        error "Please correctly enter the domain to be used "
        exit
    fi
}

validateJaegerSecure (){
    if $(validateBool $1); then
        return
    else
        error "It was not possible to identify if the application will use HTTPS"
        exit
    fi
}

validateJaegerMetrics (){
    if $(validateBool $1); then
        return
    else
        error "It was not possible to identify if the application will have metrics"
        exit
    fi
}


validateJaegerIngressClassName (){
    if [[ "$1" =~ ^([a-z]+)$ ]]; then
       return
    else
        error "Please correctly enter the ingress class name"
        exit
    fi
}

validateJaegerNamespace (){
    if $(validateNamespace $1); then
        return
    else
        error "It was not possible to identify the namespace"
        exit
    fi
}

validateJaegerPersistance (){
    if $(validateBool $1); then
        return
    else
        error "It was not possible to identify if the application will have persistance"
        exit
    fi
}


validateJaegerSsl (){
    if $(validateBool $1); then
        return
    else
        error "It was not possible to identify if the application will use SSL"
        exit
    fi
}

validateJaegerSslCrtPath (){
    if $(validatePath $1); then
        return
    else
        error "Invalid path for SSL .crt file"
        exit
    fi
}

validateJaegerSslKeyPath (){
    if $(validatePath $1); then
        return
    else
        error "Invalid path for SSL .key file"
        exit
    fi
}
