#!/usr/bin/env bash

source "$(dirname "$0")"/unix/formula/objects.sh

runFormula() {
  local VKPR_ENV_VAULT_DOMAIN VKPR_VAULT_VALUES VKPR_VAULT_CONFIG HELM_ARGS;
  formulaInputs
  setCredentials
  validateInputs

  $VKPR_KUBECTL create ns $VKPR_ENV_VAULT_NAMESPACE 2> /dev/null
  VKPR_ENV_VAULT_DOMAIN="vault.${VKPR_ENV_GLOBAL_DOMAIN}"
  VKPR_VAULT_VALUES=$(dirname "$0")/utils/vault.yaml
  VKPR_VAULT_CONFIG=$(dirname "$0")/utils/config.hcl

  startInfos
  settingVault
  if [ $DRY_RUN == false ]; then
    createStorage
    registerHelmRepository hashicorp https://helm.releases.hashicorp.com
  fi
  installApplication "vault" "hashicorp/vault" "$VKPR_ENV_VAULT_NAMESPACE" "$VKPR_VAULT_VERSION" "$VKPR_VAULT_VALUES" "$HELM_ARGS"
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Vault Install Routine"
  boldNotice "Domain: $VKPR_ENV_VAULT_DOMAIN"
  boldNotice "Secure: $VKPR_ENV_GLOBAL_SECURE"
  boldNotice "Namespace: $VKPR_ENV_VAULT_NAMESPACE"
  boldNotice "Ingress Controller: $VKPR_ENV_VAULT_INGRESS_CLASS_NAME"
  boldNotice "Storage Mode: $VKPR_ENV_VAULT_STORAGE_MODE"
  boldNotice "Auto Unseal: $VKPR_ENV_VAULT_AUTO_UNSEAL"
  bold "=============================="
}

formulaInputs() {
  # App values
  checkGlobalConfig "$MODE" "raft" "vault.storageMode" "VAULT_STORAGE_MODE"
  checkGlobalConfig "$AUTO_UNSEAL" "false" "vault.autoUnseal" "VAULT_AUTO_UNSEAL"
  checkGlobalConfig "false" "false" "vault.metrics" "VAULT_METRICS"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "$VKPR_ENV_GLOBAL_INGRESS_CLASS_NAME" "vault.ingressClassName" "VAULT_INGRESS_CLASS_NAME"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "vault.namespace" "VAULT_NAMESPACE"
  checkGlobalConfig "$SSL" "false" "vault.ssl.enabled" "VAULT_SSL"
  checkGlobalConfig "$CRT_FILE" "" "vault.ssl.crt" "VAULT_SSL_CERTIFICATE"
  checkGlobalConfig "$KEY_FILE" "" "vault.ssl.key" "VAULT_SSL_KEY"
  checkGlobalConfig "" "" "vault.ssl.secretName" "VAULT_SSL_SECRET"
  # External app values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "consul.namespace" "CONSUL_NAMESPACE"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "prometheus-stack.namespace" "GRAFANA_NAMESPACE"
}

setCredentials() {
  if [ $VKPR_ENV_VAULT_AUTO_UNSEAL == "aws" ]; then
    AWS_REGION=$($VKPR_JQ -r .credential.region "$VKPR_CREDENTIAL"/aws)
    AWS_ACCESS_KEY=$($VKPR_JQ -r .credential.accesskeyid "$VKPR_CREDENTIAL"/aws)
    AWS_SECRET_KEY=$($VKPR_JQ -r .credential.secretaccesskey "$VKPR_CREDENTIAL"/aws)
    VAULT_AWSKMS_SEAL_KEY_ID=$($VKPR_JQ -r .credential.kmskeyid $VKPR_CREDENTIAL/aws)
  fi

  if [ $VKPR_ENV_VAULT_AUTO_UNSEAL == "azure" ]; then
    AZURE_TENANT_ID=$($VKPR_JQ -r .credential.azuretenantid $VKPR_CREDENTIAL/azure)
    AZURE_CLIENT_ID=$($VKPR_JQ -r .credential.azureclientid $VKPR_CREDENTIAL/azure)
    AZURE_CLIENT_SECRET=$($VKPR_JQ -r .credential.azureclientsecret $VKPR_CREDENTIAL/azure)
    VAULT_AZUREKEYVAULT_VAULT_NAME=$($VKPR_JQ -r .credential.vaultazurekeyvaultvaultname $VKPR_CREDENTIAL/azure)
    VAULT_AZUREKEYVAULT_KEY_NAME=$($VKPR_JQ -r .credential.vaultazurekeyvaultkeyname $VKPR_CREDENTIAL/azure)
  fi
}

validateInputs() {
  #App Values
  validateVaultDomain "$VKPR_ENV_GLOBAL_DOMAIN"
  validateVaultSecure "$VKPR_ENV_GLOBAL_SECURE"
  validateVaultStorageMode "$VKPR_ENV_VAULT_STORAGE_MODE"
  validateVaultSSL "$VKPR_ENV_VAULT_SSL"
  if [[ "$VKPR_ENV_VAULT_SSL" = true ]]; then
    validateVaultCertificate "$VKPR_ENV_VAULT_SSL_CERTIFICATE"
    validateVaultKey "$VKPR_ENV_VAULT_SSL_KEY"
  fi

  if [ $VKPR_ENV_VAULT_AUTO_UNSEAL == "aws" ]; then
    validateAwsAccessKey "$AWS_ACCESS_KEY"
    validateAwsSecretKey "$AWS_SECRET_KEY"
    validateAwsRegion "$AWS_REGION"
  fi

  if [ $VKPR_ENV_VAULT_AUTO_UNSEAL == "azure" ]; then
    validateAzureTenantID "$AZURE_TENANT_ID"
    validateAzureClienteID "$AZURE_CLIENT_ID"
    validateAzureClientSecret "$AZURE_CLIENT_SECRET"
    validateAzureVaultName "$VAULT_AZUREKEYVAULT_VAULT_NAME"
    validateAzureVaultKey "$VAULT_AZUREKEYVAULT_KEY_NAME"
  fi
}

createStorage() {
  if [[ $($VKPR_KUBECTL get secret | grep vault-storage-config | cut -d " " -f1) != "vault-storage-config" ]]; then
    info "Creating storage config..."
    $VKPR_KUBECTL create secret generic vault-storage-config -n "$VKPR_ENV_VAULT_NAMESPACE" --from-file="$VKPR_VAULT_CONFIG" && \
      $VKPR_KUBECTL label secret vault-storage-config app.kubernetes.io/managed-by=vkpr app.kubernetes.io/instance=vault -n "$VKPR_ENV_VAULT_NAMESPACE" 2> /dev/null || true
  fi
}

settingVault() {
  YQ_VALUES=".global.enabled = true |
    .server.ingress.ingressClassName = \"$VKPR_ENV_VAULT_INGRESS_CLASS_NAME\" |
    .server.ingress.hosts[0].host = \"$VKPR_ENV_VAULT_DOMAIN\"
  "

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .server.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .server.ingress.tls[0].hosts[0] = \"$VKPR_ENV_VAULT_DOMAIN\" |
      .server.ingress.tls[0].secretName = \"vault-cert\"
    "
  fi

  if [[ "$VKPR_ENV_VAULT_METRICS" == true ]] && [[ $(checkPodName "$VKPR_ENV_GRAFANA_NAMESPACE" "prometheus-stack-grafana") == "true" ]]; then
    $VKPR_KUBECTL apply -n $VKPR_ENV_VAULT_NAMESPACE -f $(dirname "$0")/utils/servicemonitor.yaml
    createGrafanaDashboard "$(dirname "$0")/utils/dashboard.json" "$VKPR_ENV_GRAFANA_NAMESPACE"
    YQ_VALUES="$YQ_VALUES |
      .injector.metrics.enabled = true
    "
  fi

  if [[ "$VKPR_ENV_VAULT_SSL" == "true" ]]; then
    if [[ "$VKPR_ENV_VAULT_SSL_SECRET" == "" ]]; then
      VKPR_ENV_VAULT_SSL_SECRET="vault-certificate"
      createSslSecret "$VKPR_ENV_VAULT_SSL_SECRET" "$VKPR_ENV_VAULT_NAMESPACE" "$VKPR_ENV_VAULT_SSL_CERTIFICATE" "$VKPR_ENV_VAULT_SSL_KEY"
    fi
    YQ_VALUES="$YQ_VALUES |
      .server.ingress.tls[0].hosts[0] = \"$VKPR_ENV_VAULT_DOMAIN\" |
      .server.ingress.tls[0].secretName = \"$VKPR_ENV_VAULT_SSL_SECRET\"
     "
  fi

  if [[ "$VKPR_ENV_VAULT_STORAGE_MODE" == "raft" ]]; then
    YQ_VALUES="$YQ_VALUES |
      del(.server.ha.config) |
      .server.ha.raft.enabled = true
    "
    printf 'storage "raft" {
  path = "/vault/data"
  performance_multiplier = 1
  retry_join {
    leader_api_addr = "http://vault-0.vault-internal:8200"
  }
  retry_join {
    leader_api_addr = "http://vault-1.vault-internal:8200"
  }
  retry_join {
    leader_api_addr = "http://vault-2.vault-internal:8200"
  }
}' >> "$VKPR_VAULT_CONFIG"
    else
      YQ_VALUES="$YQ_VALUES |
      del(.server.ha.raft.config) 
      "
    printf 'storage "consul" {
  path = "vault"
  address = "consul-consul-server.%s.svc.cluster.local:8500"
}' "$VKPR_ENV_CONSUL_NAMESPACE" >> "$VKPR_VAULT_CONFIG"
  fi

  if [[ "$VKPR_ENV_VAULT_AUTO_UNSEAL" != false ]]; then
    YQ_VALUES="$YQ_VALUES |
      .server.extraEnvironmentVars.VAULT_LOG_LEVEL = \"debug\"
    "
    case "$VKPR_ENV_VAULT_AUTO_UNSEAL" in
      aws)
        YQ_VALUES="$YQ_VALUES |
          .server.extraEnvironmentVars.VAULT_SEAL_TYPE = \"awskms\" |
          .server.extraSecretEnvironmentVars[0].envName = \"AWS_REGION\" |
          .server.extraSecretEnvironmentVars[0].secretName = \"aws-unseal-vault\" |
          .server.extraSecretEnvironmentVars[0].secretKey = \"AWS_REGION\" |
          .server.extraSecretEnvironmentVars[1].envName = \"AWS_ACCESS_KEY\" |
          .server.extraSecretEnvironmentVars[1].secretName = \"aws-unseal-vault\" |
          .server.extraSecretEnvironmentVars[1].secretKey = \"AWS_ACCESS_KEY\" |
          .server.extraSecretEnvironmentVars[2].envName = \"AWS_SECRET_KEY\" |
          .server.extraSecretEnvironmentVars[2].secretName = \"aws-unseal-vault\" |
          .server.extraSecretEnvironmentVars[2].secretKey = \"AWS_SECRET_KEY\" |
          .server.extraSecretEnvironmentVars[3].envName = \"VAULT_AWSKMS_SEAL_KEY_ID\" |
          .server.extraSecretEnvironmentVars[3].secretName = \"aws-unseal-vault\" |
          .server.extraSecretEnvironmentVars[3].secretKey = \"VAULT_AWSKMS_SEAL_KEY_ID\" |
          .server.extraSecretEnvironmentVars[4].envName = \"AWS_KMS_ENDPOINT\" |
          .server.extraSecretEnvironmentVars[4].secretName = \"aws-unseal-vault\" |
          .server.extraSecretEnvironmentVars[4].secretKey = \"AWS_KMS_ENDPOINT\"
        "
        boldInfo "Setting AWS secret..."
        # shellcheck disable=SC2086
        $VKPR_YQ eval ".metadata.name = \"aws-unseal-vault\" |
          .metadata.namespace = \"$VKPR_ENV_VAULT_NAMESPACE\" |
          .data.AWS_ACCESS_KEY = \"$(echo -n "$AWS_ACCESS_KEY" | base64)\" |
          .data.AWS_SECRET_KEY = \"$(echo -n "$AWS_SECRET_KEY" | base64)\" |
          .data.AWS_REGION = \"$(echo -n "$AWS_REGION" | base64)\" |
          .data.VAULT_AWSKMS_SEAL_KEY_ID = \"$(echo -n $VAULT_AWSKMS_SEAL_KEY_ID | base64)\" |
          .data.AWS_KMS_ENDPOINT = \"$(echo -n "kms.$AWS_REGION.amazonaws.com" | base64)\"
        " "$(dirname "$0")"/utils/auto-unseal.yaml | $VKPR_KUBECTL apply -f -
        ;;
      azure)
        YQ_VALUES="$YQ_VALUES |
          .server.extraEnvironmentVars.VAULT_SEAL_TYPE = \"azurekeyvault\" |
          .server.extraSecretEnvironmentVars[0].envName = \"AZURE_TENANT_ID\" |
          .server.extraSecretEnvironmentVars[0].secretName = \"azure-unseal-vault\" |
          .server.extraSecretEnvironmentVars[0].secretKey = \"AZURE_TENANT_ID\" |
          .server.extraSecretEnvironmentVars[1].envName = \"AZURE_CLIENT_ID\" |
          .server.extraSecretEnvironmentVars[1].secretName = \"azure-unseal-vault\" |
          .server.extraSecretEnvironmentVars[1].secretKey = \"AZURE_CLIENT_ID\" |
          .server.extraSecretEnvironmentVars[2].envName = \"AZURE_CLIENT_SECRET\" |
          .server.extraSecretEnvironmentVars[2].secretName = \"azure-unseal-vault\" |
          .server.extraSecretEnvironmentVars[2].secretKey = \"AZURE_CLIENT_SECRET\" |
          .server.extraSecretEnvironmentVars[3].envName = \"VAULT_AZUREKEYVAULT_VAULT_NAME\" |
          .server.extraSecretEnvironmentVars[3].secretName = \"azure-unseal-vault\" |
          .server.extraSecretEnvironmentVars[3].secretKey = \"VAULT_AZUREKEYVAULT_VAULT_NAME\" |
          .server.extraSecretEnvironmentVars[4].envName = \"VAULT_AZUREKEYVAULT_KEY_NAME\" |
          .server.extraSecretEnvironmentVars[4].secretName = \"azure-unseal-vault\" |
          .server.extraSecretEnvironmentVars[4].secretKey = \"VAULT_AZUREKEYVAULT_KEY_NAME\"
        "
        boldInfo "Setting Azure secret..."
        # shellcheck disable=SC2086
        $VKPR_YQ eval ".metadata.name = \"azure-unseal-vault\" |
          .metadata.namespace = \"$VKPR_ENV_VAULT_NAMESPACE\" |
          .data.AZURE_TENANT_ID = \"$(echo -n $AZURE_TENANT_ID | base64)\" |
          .data.AZURE_CLIENT_ID = \"$(echo -n $AZURE_CLIENT_ID | base64)\" |
          .data.AZURE_CLIENT_SECRET = \"$(echo -n $AZURE_CLIENT_SECRET | base64)\" |
          .data.VAULT_AZUREKEYVAULT_VAULT_NAME = \"$(echo -n $VAULT_AZUREKEYVAULT_VAULT_NAME | base64)\" |
          .data.VAULT_AZUREKEYVAULT_KEY_NAME = \"$(echo -n $VAULT_AZUREKEYVAULT_KEY_NAME | base64)\"
        " "$(dirname "$0")"/utils/auto-unseal.yaml | $VKPR_KUBECTL apply -f -
        ;;
      esac
  fi

  settingVaultProvider

  debug "YQ_CONTENT = $YQ_VALUES"
}

settingVaultProvider() {
  if [[ "$VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    YQ_VALUES="$YQ_VALUES |
      del(.server) |
      del(.global) |
      .injector.enabled = false |
      .dataStorage.size = \"1Gi\" |
      .auditStorage.size = \"1Gi\" |
      .ui.enabled = true |
      .server.dev.enabled = true |
      .server.authDelegator.enabled = false |
      .ui.annotations.[\"dev.okteto.com/auto-ingress\"] = \"true\"
    "
  fi
}
