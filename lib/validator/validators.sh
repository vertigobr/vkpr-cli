#!/bin/bash

validateDomain() {
  if [[ $1 =~ ^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.)+[a-zA-Z]{2,}$ ]]; then
    echo "true"
  fi
}

validateBool(){
  if [[ $1 =~ ^true|false$ ]]; then
    echo "true"
  fi
}

validatePwd(){
  if [[ $1 =~ ^([A-Za-z0-9-]{7,})$ ]]; then
    echo "true"
  fi
}

validatePath(){
  if [[ $1 =~ ^(\/[^\/]+){1,}\/?$ ]]; then
    echo "true"
  fi
}

validatePort(){
  if [[ $1 =~ ^([1-9]{1}[0-9]{3})$ ]]; then
    echo "true"
  fi
}

validateEmail(){
  if [[ $1 =~ ^[a-z0-9.]+@[a-z0-9]+\.[a-z]+\.([a-z]+)?$ ]]; then
    echo "true"
  fi
}

validateNumber(){
  if [[ $1 =~ ^([1-9]{1})$ ]]; then
    echo "true"
  fi
}