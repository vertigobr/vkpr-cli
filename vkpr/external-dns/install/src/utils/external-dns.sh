#!/bin/sh
printf \
  "rbac:
    create: true
sources:
  - ingress
  - service
provider: digitalocean
interval: '"1m"'
digitalocean:
  apiToken: $1" > $2