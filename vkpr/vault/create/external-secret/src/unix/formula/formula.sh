#!/usr/bin/env bash

runFormula() {
  EXTERNAL_SECRET_VALUES=$(dirname "$0")"/utils/external-secret.yaml"
  
  settingExternalSecret
  createExternalSecret 
}

settingExternalSecret(){
  YQ_VALUES=".spec.refreshInterval = \"15s\""


  if [[ $SECRET_STORE_NAMESPACE == "" ]]; then
    YQ_VALUES="$YQ_VALUES | 
      .spec.secretStoreRef.kind = \"ClusterSecretStore\"
    "
  else
    YQ_VALUES="$YQ_VALUES | 
      .spec.secretStoreRef.kind = \"SecretStore\"
    "
  fi

  YQ_VALUES="$YQ_VALUES |
    .metadata.name = \"$EXTERNAL_SECRET_NAME-es\" |
    .metadata.namespace = \"$EXTERNAL_SECRET_NAMESPACE\" |
    .spec.secretStoreRef.name = \"$SECRET_STORE_REFERENCE\" |
    .spec.target.name = \"$EXTERNAL_SECRET_NAME-secret\" |
    .spec.data[0].secretKey = \"$EXTERNAL_SECRET_NAME-key\" |
    .spec.data[0].remoteRef.key = \"$SECRET_PATH\" |
    .spec.data[0].remoteRef.property = \"$SECRET_KEY\"
  "
  debug "YQ_VALUES = $YQ_VALUES"
}

createExternalSecret(){
  $VKPR_YQ -i "$YQ_VALUES" "$EXTERNAL_SECRET_VALUES"

  $VKPR_KUBECTL apply -f $EXTERNAL_SECRET_VALUES -n $EXTERNAL_SECRET_NAMESPACE
}

