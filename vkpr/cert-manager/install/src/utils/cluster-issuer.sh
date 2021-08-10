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
      - dns01:
          digitalocean:
            tokenSecretRef:
              name: digitalocean-dns
              key: $2
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production
spec:
  acme:
    # Change this email address to yours
    email: $1
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: acme-production-issuer-account-key
    solvers:
      - dns01:
          digitalocean:
            tokenSecretRef:
              name: digitalocean-dns
              key: $2" > $3