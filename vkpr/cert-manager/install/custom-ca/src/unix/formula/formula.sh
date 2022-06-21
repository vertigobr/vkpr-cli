#!/bin/bash

runFormula() {
  checkGlobalConfig "$EMAIL" "default@vkpr.com" "cert-manager.email" "CERT_MANAGER_EMAIL"
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
  bold "$(info "VKPR Cert-manager Install PowerDNS Routine")"
  bold "$(notice "Email:") ${VKPR_ENV_CERT_MANAGER_EMAIL}"
  echo "=============================="
}

installCRDS() {
  warn "Installing cert-manager CRDS beforehand..."
  $VKPR_KUBECTL apply -f "https://github.com/jetstack/cert-manager/releases/download/$VKPR_CERT_VERSION/cert-manager.crds.yaml"
}

addCertManager() {
  registerHelmRepository jetstack https://charts.jetstack.io 
}

installCertManager() {
  local YQ_VALUES=".ingressShim.defaultIssuerName = \"certmanager-issuer\" | .clusterResourceNamespace = \"$VKPR_ENV_CERT_MANAGER_NAMESPACE\""
  settingCertmanager

  if [[ $DRY_RUN == true ]]; then
    bold "---"
    mergeVkprValuesHelmArgs "cert-manager" "$VKPR_CERT_MANAGER_VALUES"
    $VKPR_YQ eval "$YQ_VALUES" "$VKPR_CERT_MANAGER_VALUES"
  else
    bold "$(info "Installing cert-manager...")"
    $VKPR_YQ eval -i "$YQ_VALUES" "$VKPR_CERT_MANAGER_VALUES"
    mergeVkprValuesHelmArgs "cert-manager" "$VKPR_CERT_MANAGER_VALUES"
    $VKPR_HELM upgrade -i --version "$VKPR_CERT_VERSION" \
      -n "$VKPR_ENV_CERT_MANAGER_NAMESPACE" --create-namespace \
      --wait -f "$VKPR_CERT_MANAGER_VALUES" cert-manager jetstack/cert-manager
  fi
}

settingCertmanager() {
  YQ_VALUES="$YQ_VALUES |
    .volumes[0].name = \"custom-ca\" |
    .volumes[0].secret.secretName = \"custom-ca-secret\" |
    .volumeMounts[0].name = \"custom-ca\" |
    .volumeMounts[0].mountPath = \"/etc/ssl/certs\" |
    .volumeMounts[0].readOnly = true
  "
}

installIssuer() {
  YQ_ISSUER_VALUES=".spec.acme.email = \"$VKPR_ENV_CERT_MANAGER_EMAIL\" |
    .metadata.namespace = \"$VKPR_ENV_CERT_MANAGER_NAMESPACE\" |
    .spec.acme.server = \"https://host.k3d.internal:9000/acme/acme/directory\" |
    .spec.acme.privateKeySecretRef.name = \"stepissuer-key\" |
    .spec.acme.solvers[0].http01.ingress.class = \"$VKPR_ENV_CERT_MANAGER_HTTP01_INGRESS\"
  "

  if [[ $DRY_RUN == true ]]; then
    bold "---"
    $VKPR_YQ eval "$YQ_ISSUER_VALUES" "$VKPR_ISSUER_VALUES"
  else
    bold "$(info "Installing Issuers and/or ClusterIssuers...")"
    $VKPR_YQ eval "$YQ_ISSUER_VALUES" "$VKPR_ISSUER_VALUES" \
    | $VKPR_KUBECTL apply -f -
  fi
}
