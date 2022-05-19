#!/bin/bash

runFormula() {
  checkGlobalConfig "$EMAIL" "default@vkpr.com" "cert-manager.email" "CERT_MANAGER_EMAIL"
  checkGlobalConfig "$ISSUER" "staging" "cert-manager.issuer" "CERT_MANAGER_ISSUER"
  checkGlobalConfig "$ISSUER_SOLVER" "DNS01" "cert-manager.solver" "CERT_MANAGER_ISSUER_SOLVER"
  checkGlobalConfig "nginx" "nginx" "cert-manager.ingress" "CERT_MANAGER_HTTP01_INGRESS"
  checkGlobalConfig "cert-manager" "cert-manager" "cert-manager.namespace" "CERT_MANAGER_NAMESPACE"

  # Todo: find why cert-manager doesnt work in another namespace
  VKPR_ENV_CERT_MANAGER_NAMESPACE="cert-manager"

  local VKPR_ISSUER_VALUES; VKPR_ISSUER_VALUES="$(dirname "$0")"/utils/issuer.yaml
  local VKPR_CERT_MANAGER_VALUES; VKPR_CERT_MANAGER_VALUES="$(dirname "$0")"/utils/cert-manager.yaml

  startInfos
  installCRDS
  addCertManager
  installCertManager
  installIssuer
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Cert-manager Install Digital Ocean Routine")"
  echoColor "bold" "$(echoColor "blue" "Email:") ${VKPR_ENV_CERT_MANAGER_EMAIL}"
  echoColor "bold" "$(echoColor "blue" "Issuer Solver:") ${VKPR_ENV_CERT_MANAGER_ISSUER_SOLVER}"
  echo "=============================="
}

installCRDS() {
  echoColor "yellow" "Installing cert-manager CRDS beforehand..."
  $VKPR_KUBECTL apply -f "https://github.com/jetstack/cert-manager/releases/download/$VKPR_CERT_VERSION/cert-manager.crds.yaml"
}

addCertManager() {
  registerHelmRepository jetstack https://charts.jetstack.io 
}

installCertManager() {
  echoColor "bold" "$(echoColor "green" "Installing cert-manager...")"
  local YQ_VALUES=".ingressShim.defaultIssuerName = \"certmanager-issuer\" | .clusterResourceNamespace = \"$VKPR_ENV_CERT_MANAGER_NAMESPACE\""

  $VKPR_YQ eval -i "$YQ_VALUES" "$VKPR_CERT_MANAGER_VALUES"
  mergeVkprValuesHelmArgs "cert-manager" "$VKPR_CERT_MANAGER_VALUES"
  $VKPR_HELM upgrade -i --version "$VKPR_CERT_VERSION" \
    -n "$VKPR_ENV_CERT_MANAGER_NAMESPACE" --create-namespace \
    --wait -f "$VKPR_CERT_MANAGER_VALUES" cert-manager jetstack/cert-manager
}

installIssuer() {
  echoColor "bold" "$(echoColor "green" "Installing Issuers and/or ClusterIssuers...")"
  local YQ_ISSUER_VALUES=".spec.acme.email = \"$VKPR_ENV_CERT_MANAGER_EMAIL\" | .metadata.namespace = \"$VKPR_ENV_CERT_MANAGER_NAMESPACE\""

  case "$VKPR_ENV_CERT_MANAGER_ISSUER" in
    staging)
        YQ_ISSUER_VALUES="$YQ_ISSUER_VALUES |
          .spec.acme.server = \"https://acme-staging-v02.api.letsencrypt.org/directory\" |
          .spec.acme.privateKeySecretRef.name = \"letsencrypt-staging-key\"
        "
      ;;
    production)
        YQ_ISSUER_VALUES="$YQ_ISSUER_VALUES |
          .spec.acme.server = \"https://acme-v02.api.letsencrypt.org/directory\" |
          .spec.acme.privateKeySecretRef.name = \"letsencrypt-production-key\"
        "
      ;;
  esac
  settingIssuer

  $VKPR_YQ eval "$YQ_ISSUER_VALUES" "$VKPR_ISSUER_VALUES" \
  | $VKPR_KUBECTL apply -f -
}

settingIssuer() {
  case "$VKPR_ENV_CERT_MANAGER_ISSUER_SOLVER" in
    HTTP01)
        YQ_ISSUER_VALUES="$YQ_ISSUER_VALUES |
          .spec.acme.solvers[0].http01.ingress.class = \"$VKPR_ENV_CERT_MANAGER_HTTP01_INGRESS\"
        "
      ;;
    DNS01)
        configureDNS01
      ;;
  esac
}

configureDNS01() {
  local DO_TOKEN; DO_TOKEN=$($VKPR_JQ -r .credential.token ~/.rit/credentials/default/digitalocean)
  validateDigitalOceanApiToken "$DO_TOKEN"

  $VKPR_KUBECTL create secret generic digitalocean-secret -n $VKPR_ENV_CERT_MANAGER_NAMESPACE --from-literal="access-token=$DO_TOKEN"
  $VKPR_KUBECTL label secret digitalocean-secret -n $VKPR_ENV_CERT_MANAGER_NAMESPACE vkpr=true app.kubernetes.io/instance=cert-manager

  YQ_ISSUER_VALUES="$YQ_ISSUER_VALUES |
    .spec.acme.solvers[0].dns01.digitalocean.tokenSecretRef.name = \"digitalocean-secret\" |
    .spec.acme.solvers[0].dns01.digitalocean.tokenSecretRef.key = \"access-token\"
  "
}