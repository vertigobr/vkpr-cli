#!/bin/sh
printf \
"installCRDs: false
ingressShim:
  defaultIssuerName: letsencrypt-staging
  defaultIssuerKind: ClusterIssuer
  defaultIssuerGroup: cert-manager.io" > $1