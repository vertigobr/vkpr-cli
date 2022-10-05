#!/usr/bin/env bash
source "$(dirname "$0")"/unix/formula/commands-operators.sh

runFormula() {
  local VKPR_CERT_MANAGER_VALUES VKPR_ISSUER_VALUES YQ_VALUES YQ_ISSUER_VALUES HELM_ARGS;
  setCredentials
  formulaInputs
  validateInputs

  $VKPR_KUBECTL create ns "$VKPR_ENV_CERT_MANAGER_NAMESPACE" > /dev/null
  VKPR_CERT_MANAGER_VALUES="$(dirname "$0")"/utils/cert-manager.yaml
  VKPR_ISSUER_VALUES="$(dirname "$0")"/utils/issuer.yaml

  startInfos
  settingCertManager
  if [[ $DRY_RUN == false ]]; then
    installCRDS
    registerHelmRepository jetstack https://charts.jetstack.io
  fi
  installApplication "cert-manager" "jetstack/cert-manager" "$VKPR_ENV_CERT_MANAGER_NAMESPACE" "$VKPR_CERT_MANAGER_VERSION" "$VKPR_CERT_MANAGER_VALUES" "$HELM_ARGS"
  settingIssuer
  installIssuer
  [ $DRY_RUN == false ] && checkComands
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Cert-manager Install Digital Ocean Routine"
  boldNotice "Email: $VKPR_ENV_CERT_MANAGER_EMAIL"
  boldNotice "Issuer Type: $VKPR_ENV_CERT_MANAGER_ISSUER_TYPE"
  boldNotice "Issuer Solver: $VKPR_ENV_CERT_MANAGER_ISSUER_SOLVER"
  boldNotice "Namespace: $VKPR_ENV_CERT_MANAGER_NAMESPACE"
  bold "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "$EMAIL" "default@vkpr.com" "cert-manager.email" "CERT_MANAGER_EMAIL"
  checkGlobalConfig "$ISSUER" "staging" "cert-manager.issuer.type" "CERT_MANAGER_ISSUER_TYPE"
  checkGlobalConfig "$ISSUER_SOLVER" "DNS01" "cert-manager.issuer.solver" "CERT_MANAGER_ISSUER_SOLVER"
  checkGlobalConfig "nginx" "nginx" "cert-manager.issuer.ingress" "CERT_MANAGER_ISSUER_INGRESS"
  # Todo: find why cert-manager doesnt work in another namespace
  #checkGlobalConfig "cert-manager" "cert-manager" "cert-manager.namespace" "CERT_MANAGER_NAMESPACE"
  VKPR_ENV_CERT_MANAGER_NAMESPACE="cert-manager"
}

setCredentials() {
  DO_TOKEN=$($VKPR_JQ -r .credential.token "$VKPR_CREDENTIAL"/digitalocean)
}

validateInputs() {
  validateDigitalOceanApiToken "$DO_TOKEN"

  validateCertManagerEmail "$VKPR_ENV_CERT_MANAGER_EMAIL"
  validateIssuerType "$VKPR_ENV_CERT_MANAGER_ISSUER_TYPE"
  validateIssuerSolver "$VKPR_ENV_CERT_MANAGER_ISSUER_SOLVER"
}

installCRDS() {
  info "Installing cert-manager CRDS beforehand..."
  $VKPR_KUBECTL apply -f "https://github.com/jetstack/cert-manager/releases/download/$VKPR_CERT_MANAGER_VERSION/cert-manager.crds.yaml"
}

settingCertManager() {
  YQ_VALUES=".ingressShim.defaultIssuerName = \"certmanager-issuer\" |
    .clusterResourceNamespace = \"$VKPR_ENV_CERT_MANAGER_NAMESPACE\"
  "

  debug "YQ_CONTENT = $YQ_VALUES"
}

installIssuer() {
  boldInfo "Installing Issuers and/or ClusterIssuers..."
  $VKPR_YQ eval "$YQ_ISSUER_VALUES" "$VKPR_ISSUER_VALUES" \
  | $VKPR_KUBECTL apply -f -
}

settingIssuer() {
  YQ_ISSUER_VALUES=".spec.acme.email = \"$VKPR_ENV_CERT_MANAGER_EMAIL\" |
    .metadata.namespace = \"$VKPR_ENV_CERT_MANAGER_NAMESPACE\"
  "

  if [[ "$VKPR_ENV_CERT_MANAGER_ISSUER_TYPE" == "production" ]]; then
    YQ_ISSUER_VALUES="$YQ_ISSUER_VALUES |
      .spec.acme.server = \"https://acme-v02.api.letsencrypt.org/directory\" |
      .spec.acme.privateKeySecretRef.name = \"letsencrypt-production-key\"
    "
  else
    YQ_ISSUER_VALUES="$YQ_ISSUER_VALUES |
      .spec.acme.server = \"https://acme-staging-v02.api.letsencrypt.org/directory\" |
      .spec.acme.privateKeySecretRef.name = \"letsencrypt-staging-key\"
    "
  fi

  if [[ "$VKPR_ENV_CERT_MANAGER_ISSUER_SOLVER" == "DNS01" ]]; then
    createDOCredentialSecret $VKPR_ENV_CERT_MANAGER_NAMESPACE $DO_TOKEN
    YQ_ISSUER_VALUES="$YQ_ISSUER_VALUES |
      .spec.acme.solvers[0].dns01.digitalocean.tokenSecretRef.name = \"vkpr-do-credential\" |
      .spec.acme.solvers[0].dns01.digitalocean.tokenSecretRef.key = \"api-token\"
    "
  else
    YQ_ISSUER_VALUES="$YQ_ISSUER_VALUES |
      .spec.acme.solvers[0].http01.ingress.class = \"$VKPR_ENV_CERT_MANAGER_ISSUER_INGRESS\"
    "
  fi

  debug "YQ_ISSUER_CONTENT = $YQ_ISSUER_VALUES"
}

checkComands (){
  COMANDS_EXISTS=$($VKPR_YQ eval ".cert-manager | has(\"commands\")" "$VKPR_FILE" 2> /dev/null )
  debug "$COMANDS_EXISTS"
  if [ "$COMANDS_EXISTS" == true ]; then
    bold "=============================="
    boldInfo "Checking additional cert-manager commands..." 
    if [ $($VKPR_YQ eval ".cert-manager.commands | has(\"wildcard\")" "$VKPR_FILE") == true ]; then
      checkGlobalConfig "" "" "cert-manager.commands.wildcard.namespace" "WILDCARD_NAMESPACE"
      createWildcard "$VKPR_ENV_GLOBAL_DOMAIN" "$VKPR_ENV_CERT_MANAGER_NAMESPACE" "$(dirname "$0")"/utils/certificate.yaml
    fi
  fi
}
