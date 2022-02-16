#!/bin/sh

runFormula() {
  local VKPR_ISSUER_VALUES=$(dirname "$0")/utils/issuer.yaml
  local VKPR_CERT_MANAGER_VALUES=$(dirname "$0")/utils/cert-manager.yaml

  checkGlobalConfig $EMAIL "default@vkpr.com" "cert-manager.email" "EMAIL"
  checkGlobalConfig $ISSUER "staging" "cert-manager.issuer" "CERT_ISSUER"
  checkGlobalConfig $ISSUER_SOLVER "DNS01" "cert-manager.solver" "ISSUER_SOLVER"
  checkGlobalConfig "nginx" "nginx" "cert-manager.ingress" "HTTP01_INGRESS"
  checkGlobalConfig "cert-manager" "cert-manager" "cert-manager.namespace" "NAMESPACE"

  # Todo: find why cert-manager doesnt work in another namespace
  VKPR_ENV_NAMESPACE="cert-manager"

  startInfos
  installCRDS
  addCertManager
  installCertManager
  installIssuer
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Cert-manager Install Routine")"
  echoColor "bold" "$(echoColor "blue" "Email:") ${VKPR_ENV_EMAIL}"
  echoColor "bold" "$(echoColor "blue" "Issuer Solver:") ${VKPR_ENV_ISSUER_SOLVER}"
  echoColor "bold" "$(echoColor "blue" "Provider:") ${CLOUD_PROVIDER}"
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
  local YQ_VALUES='.ingressShim.defaultIssuerName = "certmanager-issuer" | .clusterResourceNamespace = "'$VKPR_ENV_NAMESPACE'"'
  settingCertmanager
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_CERT_MANAGER_VALUES" \
  | $VKPR_HELM upgrade -i -f - \
      -n $VKPR_ENV_NAMESPACE --create-namespace \
      --version "$VKPR_CERT_VERSION" \
      --wait \
      cert-manager jetstack/cert-manager
}

settingCertmanager() {
  if [[ $VKPR_ENV_CERT_ISSUER = "custom-acme" ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .volumes[0].name = "custom-ca" |
      .volumes[0].secret.secretName = "custom-ca-secret" |
      .volumeMounts[0].name = "custom-ca" |
      .volumeMounts[0].mountPath = "/etc/ssl/certs" |
      .volumeMounts[0].readOnly = "true"
    '
  fi

  mergeVkprValuesHelmArgs "cert-manager" $VKPR_INGRESS_VALUES
}

installIssuer() {
  echoColor "bold" "$(echoColor "green" "Installing Issuers and/or ClusterIssuers...")"
  local YQ_ISSUER_VALUES='.spec.acme.email = "'$VKPR_ENV_EMAIL'" | .metadata.namespace = "'$VKPR_ENV_NAMESPACE'"'
  case $VKPR_ENV_CERT_ISSUER in
    staging)
        YQ_ISSUER_VALUES=''$YQ_ISSUER_VALUES' |
          .spec.acme.server = "https://acme-staging-v02.api.letsencrypt.org/directory" |
          .spec.acme.privateKeySecretRef.name = "letsencrypt-staging-key"
        '
      ;;
    production)
        YQ_ISSUER_VALUES=''$YQ_ISSUER_VALUES' |
          .spec.acme.server = "https://acme-v02.api.letsencrypt.org/directory" |
          .spec.acme.privateKeySecretRef.name = "letsencrypt-production-key"
        '
      ;;
    custom-acme)
        YQ_ISSUER_VALUES=''$YQ_ISSUER_VALUES' |
          .spec.acme.server = "https://host.k3d.internal:9000/acme/acme/directory" |
          .spec.acme.privateKeySecretRef.name = "stepissuer-key" |
          .spec.acme.solvers[0].http01.ingress.class = "'$VKPR_ENV_HTTP01_INGRESS'"
        '
      ;;
  esac
  settingIssuer
  $VKPR_YQ eval "$YQ_ISSUER_VALUES" "$VKPR_ISSUER_VALUES" \
  | $VKPR_KUBECTL apply -f -
}

settingIssuer() {
  case $VKPR_ENV_ISSUER_SOLVER in
    HTTP01)
        YQ_ISSUER_VALUES=''$YQ_ISSUER_VALUES' |
          .spec.acme.solvers[0].http01.ingress.class = "'$VKPR_ENV_HTTP01_INGRESS'"
        '
      ;;
    DNS01)
        configureDNS01
      ;;
  esac
}

configureDNS01() {
  case $CLOUD_PROVIDER in
    aws)
        AWS_REGION=$(cat ~/.rit/credentials/default/aws | $VKPR_JQ -r .credential.region)
        AWS_ACCESS_KEY=$(cat ~/.rit/credentials/default/aws | $VKPR_JQ -r .credential.accesskeyid)
        AWS_SECRET_KEY=$(cat ~/.rit/credentials/default/aws | $VKPR_JQ -r .credential.secretaccesskey)
        validateAwsAccessKey $AWS_ACCESS_KEY
        validateAwsSecretKey $AWS_SECRET_KEY
        validateAwsRegion $AWS_REGION
        $VKPR_KUBECTL create secret generic route53-secret -n $VKPR_ENV_NAMESPACE --from-literal="secret-access-key=$AWS_SECRET_KEY"
        $VKPR_KUBECTL label secret route53-secret -n $VKPR_ENV_NAMESPACE vkpr=true app.kubernetes.io/instance=cert-manager
        YQ_ISSUER_VALUES=''$YQ_ISSUER_VALUES' |
          .spec.acme.solvers[0].dns01.route53.region = "'$AWS_REGION'" |
          .spec.acme.solvers[0].dns01.route53.accessKeyID = "'$AWS_ACCESS_KEY'" |
          .spec.acme.solvers[0].dns01.route53.secretAccessKeySecretRef.name = "route53-secret" |
          .spec.acme.solvers[0].dns01.route53.secretAccessKeySecretRef.key = "secret-access-key" |
          .spec.acme.solvers[0].dns01.route53.hostedZoneID = "'$AWS_HOSTEDZONE_ID'"
        '
      ;;
    digitalocean)
        DO_TOKEN=$(cat ~/.rit/credentials/default/digitalocean | $VKPR_JQ -r .credential.token)
        validateDigitalOceanApiToken $DO_TOKEN
        $VKPR_KUBECTL create secret generic digitalocean-secret -n $VKPR_ENV_NAMESPACE --from-literal="access-token=$DO_TOKEN"
        $VKPR_KUBECTL label secret digitalocean-secret -n $VKPR_ENV_NAMESPACE vkpr=true app.kubernetes.io/instance=cert-manager
        YQ_ISSUER_VALUES=''$YQ_ISSUER_VALUES' |
          .spec.acme.solvers[0].dns01.digitalocean.tokenSecretRef.name = "digitalocean-secret" |
          .spec.acme.solvers[0].dns01.digitalocean.tokenSecretRef.key = "access-token"
        '
      ;;
  esac
}