#!/bin/sh
printf \
"ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: '"true"'
  pathType: Prefix
  hosts:
    - host: whoami.vkpr-dev.vertigo.com.br
      paths: ['"/"']
  tls:
  - hosts:
    - whoami.vkpr-dev.vertigo.com.br
    secretName: whoami-cert" > $1