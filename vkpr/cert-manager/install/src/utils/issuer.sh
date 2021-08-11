#!/bin/sh
printf \
"apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    email: $1
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: acme-staging-issuer-account-key
    solvers:
      - selector:
          dnsZones:
            - '"whoami.vkpr-dev.vertigo.com.br"'
        dns01:
          digitalocean:
            tokenSecretRef:
              name: digitalocean-dns
              key: access-token" > $2