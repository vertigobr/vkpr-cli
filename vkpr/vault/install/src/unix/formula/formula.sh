#!/bin/bash

runFormula() {
  # Global values
  checkGlobalConfig "$DOMAIN" "localhost" "global.domain" "GLOBAL_DOMAIN"
  checkGlobalConfig "$SECURE" "false" "global.secure" "GLOBAL_SECURE"
  checkGlobalConfig "nginx" "nginx" "global.ingressClassName" "GLOBAL_INGRESS"
  checkGlobalConfig "$VKPR_K8S_NAMESPACE" "vkpr" "global.namespace" "GLOBAL_NAMESPACE"
  
  # App values
  checkGlobalConfig "$VAULT_MODE" "raft" "vault.storageMode" "VAULT_MODE"
  checkGlobalConfig "$VAULT_AUTO_UNSEAL" "false" "vault.autoUnseal" "VAULT_AUTO_UNSEAL"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_INGRESS" "$VKPR_ENV_GLOBAL_INGRESS" "vault.ingressClassName" "VAULT_INGRESS"
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "vault.namespace" "VAULT_NAMESPACE"

  # External app values
  checkGlobalConfig "$VKPR_ENV_GLOBAL_NAMESPACE" "$VKPR_ENV_GLOBAL_NAMESPACE" "consul.namespace" "CONSUL_NAMESPACE"

  local VKPR_ENV_VAULT_DOMAIN="vault.${VKPR_ENV_GLOBAL_DOMAIN}" \
        RIT_CREDENTIALS_PATH=~/.rit/credentials/default

  local VKPR_VAULT_VALUES; VKPR_VAULT_VALUES=$(dirname "$0")/utils/vault.yaml
  local VKPR_VAULT_CONFIG; VKPR_VAULT_CONFIG=$(dirname "$0")/utils/config.hcl

  [[ $DRY_RUN == true ]] && DRY_RUN_FLAGS="--dry-run=client -o yaml"
  
  startInfos
  configureRepository
  installVault
}

startInfos() {
  echo "=============================="
  bold "$(info "VKPR Vault Install Routine")"
  bold "$(notice "Vault UI Domain:") ${VKPR_ENV_VAULT_DOMAIN}"
  bold "$(notice "Vault UI HTTPS:") ${VKPR_ENV_GLOBAL_SECURE}"
  bold "$(notice "Ingress Controller:") ${VKPR_ENV_VAULT_INGRESS}"
  bold "$(notice "Storage Mode:") ${VKPR_ENV_VAULT_MODE}"
  bold "$(notice "Auto Unseal:") ${VKPR_ENV_VAULT_AUTO_UNSEAL}"
  echo "=============================="
}

configureRepository() {
  registerHelmRepository hashicorp https://helm.releases.hashicorp.com
}

installVault() {
  local YQ_VALUES=".global.enabled = true"
  settingVault
  
  if [[ $DRY_RUN == true ]]; then
    echoColor "bold" "---"
    $VKPR_YQ eval "$YQ_VALUES" "$VKPR_VAULT_VALUES"
  else
    info "Installing Vault..."
    $VKPR_YQ eval -i "$YQ_VALUES" "$VKPR_VAULT_VALUES"
    mergeVkprValuesHelmArgs "vault" "$VKPR_VAULT_VALUES"
    $VKPR_HELM upgrade -i --version "$VKPR_VAULT_VERSION" \
      --namespace "$VKPR_ENV_VAULT_NAMESPACE" --create-namespace \
      --wait -f "$VKPR_VAULT_VALUES" vault hashicorp/vault
  fi

  if [[ $($VKPR_KUBECTL get secret -n "$VKPR_ENV_VAULT_NAMESPACE" | grep vault-storage-config | cut -d " " -f1) != "vault-storage-config" ]]; then
    info "Creating storage config..."
    $VKPR_KUBECTL create secret generic vault-storage-config -n "$VKPR_ENV_VAULT_NAMESPACE" --from-file="$VKPR_VAULT_CONFIG" $DRY_RUN_FLAGS && \
      $VKPR_KUBECTL label secret vault-storage-config vkpr=true app.kubernetes.io/instance=vault -n "$VKPR_ENV_VAULT_NAMESPACE" 2> /dev/null || true
  fi
}

settingVault() {
  YQ_VALUES="$YQ_VALUES |
    .server.ingress.ingressClassName = \"$VKPR_ENV_VAULT_INGRESS\" |
    .server.ingress.hosts[0].host = \"$VKPR_ENV_VAULT_DOMAIN\"
  "

  if [[ "$VKPR_ENV_GLOBAL_SECURE" == true ]]; then
    YQ_VALUES="$YQ_VALUES |
      .server.ingress.annotations.[\"kubernetes.io/tls-acme\"] = \"true\" |
      .server.ingress.tls[0].hosts[0] = \"$VKPR_ENV_VAULT_DOMAIN\" |
      .server.ingress.tls[0].secretName = \"vault-cert\"
    "
  fi

  if [[ "$VKPR_ENV_VAULT_AUTO_UNSEAL" != false ]]; then
    $VKPR_KUBECTL create ns "$VKPR_ENV_VAULT_NAMESPACE" 2> /dev/null
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
        AWS_ACCESS_KEY=$($VKPR_JQ -r .credential.accesskeyid $RIT_CREDENTIALS_PATH/aws)
        AWS_SECRET_KEY=$($VKPR_JQ -r .credential.secretaccesskey $RIT_CREDENTIALS_PATH/aws)
        AWS_REGION=$($VKPR_JQ -r .credential.region $RIT_CREDENTIALS_PATH/aws)
        validateAwsAccessKey "$AWS_ACCESS_KEY"
        validateAwsSecretKey "$AWS_SECRET_KEY"
        validateAwsRegion "$AWS_REGION"
        echoColor "bold" "$(echoColor "green" "Setting AWS secret...")"
        $VKPR_YQ eval ".metadata.name = \"aws-unseal-vault\" |
          .metadata.namespace = \"$VKPR_ENV_VAULT_NAMESPACE\" |
          .data.AWS_ACCESS_KEY = \"$(echo -n "$AWS_ACCESS_KEY" | base64)\" |
          .data.AWS_SECRET_KEY = \"$(echo -n "$AWS_SECRET_KEY" | base64)\" |
          .data.AWS_REGION = \"$(echo -n "$AWS_REGION" | base64)\" |
          .data.VAULT_AWSKMS_SEAL_KEY_ID = \"$(echo -n "$($VKPR_JQ -r .credential.kmskeyid $RIT_CREDENTIALS_PATH/aws)" | base64)\" |
          .data.AWS_KMS_ENDPOINT = \"$(echo -n "kms.$AWS_REGION.amazonaws.com" | base64)\"
        " "$(dirname "$0")"/utils/auto-unseal.yaml | $VKPR_KUBECTL apply -f - $DRY_RUN_FLAGS
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
        echoColor "bold" "$(echoColor "green" "Setting Azure secret...")"
        $VKPR_YQ eval ".metadata.name = \"azure-unseal-vault\" |
          .metadata.namespace = \"$VKPR_ENV_VAULT_NAMESPACE\" |
          .data.AZURE_TENANT_ID = \"$(echo -n "$($VKPR_JQ -r .credential.azuretenantid $RIT_CREDENTIALS_PATH/azure)" | base64)\" |
          .data.AZURE_CLIENT_ID = \"$(echo -n "$($VKPR_JQ -r .credential.azureclientid $RIT_CREDENTIALS_PATH/azure)" | base64)\" |
          .data.AZURE_CLIENT_SECRET = \"$(echo -n "$($VKPR_JQ -r .credential.azureclientsecret $RIT_CREDENTIALS_PATH/azure)" | base64)\" |
          .data.VAULT_AZUREKEYVAULT_VAULT_NAME = \"$(echo -n "$($VKPR_JQ -r .credential.vaultazurekeyvaultvaultname $RIT_CREDENTIALS_PATH/azure)" | base64)\" |
          .data.VAULT_AZUREKEYVAULT_KEY_NAME = \"$(echo -n "$($VKPR_JQ -r .credential.vaultazurekeyvaultkeyname $RIT_CREDENTIALS_PATH/azure)" | base64)\"
        " "$(dirname "$0")"/utils/auto-unseal.yaml | $VKPR_KUBECTL apply -f - $DRY_RUN_FLAGS
        ;;
      esac
  fi

  if [[ "$VKPR_ENV_VAULT_MODE" == "raft" ]]; then
  YQ_VALUES="$YQ_VALUES |
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
    printf 'storage "consul" {
  path = "vault"
  address = "consul-consul-server.%s.svc.cluster.local:8500"
}' "$VKPR_ENV_CONSUL_NAMESPACE" >> "$VKPR_VAULT_CONFIG"
  fi
}
