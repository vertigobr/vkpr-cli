#!/bin/sh

kcadm.sh config credentials --server http://localhost:8080 \
  --realm master --user "LOGIN_USERNAME" --password "LOGIN_PASSWORD" \
  --config /tmp/kcadm.config

kcadm.sh create identity-provider/instances -r REALM_NAME -s enabled=true \
  -s alias=PROVIDER_NAME -s providerId=PROVIDER_NAME \
  -s config.clientId=CLIENT_ID -s config.clientSecret=CLIENT_SECRET \
  --config /tmp/kcadm.config

rm /tmp/kcadm.config
