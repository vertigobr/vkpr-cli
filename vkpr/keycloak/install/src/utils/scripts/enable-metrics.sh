#!/bin/sh

kcadm.sh config credentials --server http://localhost:8080 \
  --realm master --user "LOGIN_USERNAME" --password "LOGIN_PASSWORD" \
  --config /tmp/kcadm.config

kcadm.sh update events/config \
  -s "eventsEnabled=true" -s "adminEventsEnabled=true" -s "eventsListeners+=metrics-listener" \
  --config /tmp/kcadm.config

rm /tmp/kcadm.config
