#!/usr/bin/env bash

validateDomain() {
  if [[ $1 =~ ^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.)+([a-zA-Z]{2,})|localhost$ ]]; then
    echo "true"
    return
  fi
  echo "false"
}

validateBool(){
  if [[ $1 =~ ^true|false$ ]]; then
    echo "true"
    return
  fi
  echo "false"
}

validatePwd(){
  if [[ $1 =~ ^([A-Za-z0-9-]{7,})$ ]]; then
    echo "true"
    return
  fi
  echo "false"
}

validatePath(){
  if [[ $1 =~ ^(\/[^\/]+){1,}\/?$ ]]; then
    echo "true"
    return
  fi
  echo "false"
}

validatePort(){
  if [[ $1 =~ ^([1-9]{1}[0-9]{3})$ ]]; then
    echo "true"
    return
  fi
  echo "false"
}

validateEmail(){
  if [[ $1 =~ ^[a-z0-9.]+@[a-z0-9]+\.[a-z]+(\.[a-z]+)?$ ]]; then
    echo "true"
    return
  fi
  echo "false"
}

validateNumber(){
  if [[ $1 =~ ^([1-9]{1})$ ]]; then
    echo "true"
    return
  fi
  echo "false"
}

validateNamespace(){
  if [[ $1 =~ ^([a-z0-9]([-a-z0-9]*[a-z0-9])?)$ ]]; then
    echo "true"
    return
  fi
  echo "false"
}

validateUrl(){
local REG='^(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]\.[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]$'
  if [[ $1 =~ $REG ]]; then
    echo "true"
    return
  fi
  echo "false"
}

validateVolume(){
local REG='^([0-9]{1,4}Gi)$'
  if [[ $1 =~ $REG ]]; then
    echo "true"
    return
  else
    echo "false"
 fi
}
