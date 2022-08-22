#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Okta validators
# -----------------------------------------------------------------------------

validateOktaClientId (){
  if [[ $1 =~ ^([A-Za-z0-9]{20})$ ]]; then
      return
  else
      error "The value used for OKTA_CLIENT_ID \"$1\" is invalid: OKTA_CLIENT_ID must consist of lowercase, uppercase or alphanumeric characters, (e.g. 'Aa1Bb2Cc3Dd4Ee5Ff6Gg', regex used for validation is ^([A-Za-z0-9]{20})$')"
      exit
  fi
}

validateOktaClientSecret (){
  if [[ $1 =~ ^([a-zA-Z0-9_\-]{40})$ ]]; then
      return
  else
      error "The value used for OKTA_CLIENT_ID \"$1\" is invalid: OKTA_CLIENT_ID must consist of lowercase, uppercase or '_' alphanumeric characters, (e.g. 'Aa1Bb2Cc3Dd4Ee5Ff6Gg7Hh8Ii9Jj10Kk11Ll12M', regex used for validation is ^([a-zA-Z0-9_\-]{40})$)"
      exit
  fi
}

validateOktaClientAudience (){
  if [[ $1 =~ ^(http|https):\/\/[a-z0-9-]+\.(okta.com).* ]]; then
      return
  else
      error "The value used for OKTA_CLIENT_ID \"$1\" is invalid: OKTA_CLIENT_ID must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'https://example.okta.com', regex used for validation is ^(http|https):\/\/[a-z0-9-]+\.(okta.com).*)"
      exit
  fi
}

