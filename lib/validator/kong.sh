#!/usr/bin/env bash

validateKongDomain() {
  if $(validateDomain $1); then
    return
  else
    error "Please correctly enter the domain to be used "
    exit
  fi
}

validateKongSecure() {
  if $(validateBool "$1"); then
    return
  else
    error "It was not possible to identify if the application will have HTTPS"
    exit
  fi
}

validateKongHA(){
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will have High Availability "
    exit
  fi
}

validateKongMetrics(){
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will have Metrics"
    exit
  fi
}

validateKongEnterprise() {
  if $(validateBool $1); then
    return
  else
    error "It was not possible to identify if the application will use enterprise license!"
    exit
  fi
}

validateKongEnterpriseLicensePath() {
  if $(validatePath $1); then
    return
  else
    error "Invalid path"
    exit
  fi
}

validateKongRBACPwd() {
  if $(validatePwd $1); then
    return
  else
    error "Invalid password"
    exit
  fi
}

validateKongDeployment() {
  if [[ "$1" =~ ^(standard|hybrid|dbless)$ ]]; then
    return
  else
    error "It was not possible to identify the type of deployment of Kong"
    exit
  fi
}

validateKongNamespace() {
  if  $(validateNamespace $1); then
    return
  else
    error "Invalid namespace"
    exit
  fi
}
