#!/usr/bin/env bash

runFormula() {
  SECRET_STORE_VALUES=$(dirname "$0")"/utils/secret-store.yaml"
  
  validateInputs
  createSecrets 
  settingSecretStore
  createSecretStore
}

validateInputs(){
# Vault
  # validateSecretStoreAddr "$VAULT_STORE_ADDR"
  # validateSecretStorePath "$VAULT_SECRET_PATH"
[[ $SECRET_STORE_NAMESPACE != "" ]] && validateSecretStoreNamespace "$SECRET_STORE_NAMESPACE"
}

createSecrets(){

  case $PROVIDER in
    vault) 
      if [[ $SECRET_STORE_NAMESPACE == "" ]]; then
        $VKPR_KUBECTL create secret generic vkpr-vault-token --from-literal=token="$VAULT_TOKEN"
      else
        $VKPR_KUBECTL create secret generic vkpr-vault-token -n $SECRET_STORE_NAMESPACE --from-literal=token="$VAULT_TOKEN"
      fi
    ;;
  esac
}

settingSecretStore(){
  YQ_VALUES=".spec.retrySettings.maxRetries = 5"

  if [[ $SECRET_STORE_NAMESPACE == "" ]]; then
    YQ_VALUES="$YQ_VALUES |
      .kind = \"ClusterSecretStore\"
    "
  else
    YQ_VALUES="$YQ_VALUES |
    .metadata.namespace = \"$SECRET_STORE_NAMESPACE\"
    "
  fi

  case $PROVIDER in
    vault) 
      YQ_VALUES="$YQ_VALUES |
        .spec.provider.vault.server = \"$VAULT_STORE_ADDR\" |
        .spec.provider.vault.version = \"$VAULT_KV_VERSION\" 
      "
    ;;
  esac

  debug "YQ_VALUES = $YQ_VALUES"

}

createSecretStore(){
  $VKPR_YQ eval -i "$YQ_VALUES" "$SECRET_STORE_VALUES"
  if [[ $SECRET_STORE_NAMESPACE == "" ]]; then
    $VKPR_KUBECTL apply -f $SECRET_STORE_VALUES 
  else
    $VKPR_KUBECTL apply -f $SECRET_STORE_VALUES -n $SECRET_STORE_NAMESPACE
  fi

}

