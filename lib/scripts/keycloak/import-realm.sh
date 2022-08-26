#!/bin/sh

kcadm.sh config credentials --server http://localhost:8080 \
  --realm master --user LOGIN_USERNAME --password LOGIN_PASSWORD \
  --config /tmp/kcadm.config

kcadm.sh create realms -f /tmp/realm.json \
  --config /tmp/kcadm.config

rm -f /tmp/kcadm.config /tmp/realm.json
