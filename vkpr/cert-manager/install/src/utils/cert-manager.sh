#!/bin/sh
printf \
"installCRDs: false
ingressShim:
  defaultIssuerName: letsencrypt-staging
  defaultIssuerKind: Issuer
  defaultIssuerGroup: cert-manager.io" > $1