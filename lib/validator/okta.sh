#!/bin/bash

# -----------------------------------------------------------------------------
# Okta validators
# -----------------------------------------------------------------------------

validateOktaClientId (){
  if [[ $1 =~ ^([A-Za-z0-9]{20})$ ]]; then
      return
  else
      error 'Please correctly enter the Okta client id, fix the credential with the command  "rit set credential"'
      exit
  fi 
}

validateOktaClientSecret (){
  if [[ $1 =~ ^([a-zA-Z0-9]{40})$ ]]; then
      return
  else
      error 'Please correctly enter the Okta client secret, fix the credential with the command  "rit set credential"'
      exit
  fi 
}

validateOktaClientAudience (){
  if [[ $1 =~ ^(http|https):\/\/[a-z0-9-]+\.(okta.com).* ]]; then
      return
  else
      error 'Please correctly enter the Okta client audience, fix the credential with the command  "rit set credential"'
      exit
  fi 
}

