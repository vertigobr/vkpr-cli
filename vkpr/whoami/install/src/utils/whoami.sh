#!/bin/sh
printf \
"ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: '"true"'
  pathType: Prefix
  hosts:
    - host: $2
      paths: ['"/"']
  tls:
  - hosts:
    - $2
    secretName: whoami-cert" > $1