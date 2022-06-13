#!/bin/bash

runFormula() {
  checkGlobalConfig "$EMAIL" "default@vkpr.com" "cert-manager.email" "CERT_MANAGER_EMAIL"
  checkGlobalConfig "$ISSUER" "staging" "cert-manager.issuer.type" "CERT_MANAGER_ISSUER_TYPE"
  checkGlobalConfig "$ISSUER_SOLVER" "DNS01" "cert-manager.issuer.solver" "CERT_MANAGER_ISSUER_SOLVER"
  checkGlobalConfig "nginx" "nginx" "cert-manager.issuer.ingress" "CERT_MANAGER_ISSUER_INGRESS"
  checkGlobalConfig "cert-manager" "cert-manager" "cert-manager.namespace" "CERT_MANAGER_NAMESPACE"

  # Todo: find why cert-manager doesnt work in another namespace
  VKPR_ENV_CERT_MANAGER_NAMESPACE="cert-manager"

  local VKPR_ISSUER_VALUES; VKPR_ISSUER_VALUES="$(dirname "$0")"/utils/issuer.yaml
  local VKPR_CERT_MANAGER_VALUES; VKPR_CERT_MANAGER_VALUES="$(dirname "$0")"/utils/cert-manager.yaml

  [[ $DRY_RUN == true ]] && DRY_RUN_FLAGS="--dry-run=client -o yaml"

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
  local YQ_VALUES=".ingressShim.defaultIssuerName = \"certmanager-issuer\" | .clusterResourceNamespace = \"$VKPR_ENV_CERT_MANAGER_NAMESPACE\""

  if [[ $DRY_RUN == true ]]; then
    echoColor "bold" "---"
    $VKPR_YQ eval "$YQ_VALUES" "$VKPR_CERT_MANAGER_VALUES"
    mergeVkprValuesHelmArgs "cert-manager" "$VKPR_CERT_MANAGER_VALUES"    
  else
    echoColor "bold" "$(echoColor "green" "Installing cert-manager...")"
    $VKPR_YQ eval -i "$YQ_VALUES" "$VKPR_CERT_MANAGER_VALUES"
    mergeVkprValuesHelmArgs "cert-manager" "$VKPR_CERT_MANAGER_VALUES"
    $VKPR_HELM upgrade -i --version "$VKPR_CERT_VERSION" \
      -n "$VKPR_ENV_CERT_MANAGER_NAMESPACE" --create-namespace \
      --wait -f "$VKPR_CERT_MANAGER_VALUES" cert-manager jetstack/cert-manager
  fi
}

installIssuer() {
  local YQ_ISSUER_VALUES=".spec.acme.email = \"$VKPR_ENV_CERT_MANAGER_EMAIL\" | .metadata.namespace = \"$VKPR_ENV_CERT_MANAGER_NAMESPACE\""

  case "$VKPR_ENV_CERT_MANAGER_ISSUER_TYPE" in
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

  if [[ $DRY_RUN == true ]]; then
    echoColor "bold" "---"
    $VKPR_YQ eval "$YQ_ISSUER_VALUES" "$VKPR_ISSUER_VALUES"
  else
    echoColor "bold" "$(echoColor "green" "Installing Issuers and/or ClusterIssuers...")"
    $VKPR_YQ eval "$YQ_ISSUER_VALUES" "$VKPR_ISSUER_VALUES" \
    | $VKPR_KUBECTL apply -f -
  fi
}

settingIssuer() {
  case "$VKPR_ENV_CERT_MANAGER_ISSUER_SOLVER" in
    HTTP01)
        YQ_ISSUER_VALUES="$YQ_ISSUER_VALUES |
          .spec.acme.solvers[0].http01.ingress.class = \"$VKPR_ENV_CERT_MANAGER_ISSUER_INGRESS\"
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

  echoColor "bold" "$(echoColor "green" "Setting DO secret...")"
  # shellcheck disable=SC2086
  $VKPR_KUBECTL create secret generic digitalocean-secret -n $VKPR_ENV_CERT_MANAGER_NAMESPACE --from-literal="access-token=$DO_TOKEN" $DRY_RUN_FLAGS
  $VKPR_KUBECTL label secret digitalocean-secret -n $VKPR_ENV_CERT_MANAGER_NAMESPACE vkpr=true app.kubernetes.io/instance=cert-manager 2> /dev/null

  YQ_ISSUER_VALUES="$YQ_ISSUER_VALUES |
    .spec.acme.solvers[0].dns01.digitalocean.tokenSecretRef.name = \"digitalocean-secret\" |
    .spec.acme.solvers[0].dns01.digitalocean.tokenSecretRef.key = \"access-token\"
  "
}
