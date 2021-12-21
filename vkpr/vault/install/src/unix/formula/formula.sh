#!/bin/bash

runFormula() {
  local VKPR_VAULT_VALUES=$(dirname "$0")/utils/vault.yaml
  local VKPR_VAULT_CONFIG=$(dirname "$0")/utils/config.hcl
  local INGRESS_CONTROLLER="nginx"
  echoColor "green" "Installing vault..."

  checkGlobalConfig $DOMAIN "localhost" "domain" "DOMAIN"
  checkGlobalConfig $SECURE "false" "secure" "SECURE"
  checkGlobalConfig $VAULT_MODE "raft" "vault.mode" "VAULT_MODE"
  checkGlobalConfig $INGRESS_CONTROLLER "nginx" "vault.ingressClassName" "VAULT_INGRESS"

  local VKPR_ENV_VAULT_DOMAIN="vault.${VKPR_ENV_DOMAIN}"
  
  configureRepository
  installVault
}

configureRepository() {
  registerHelmRepository hashicorp https://helm.releases.hashicorp.com
}

settingVault() {
  YQ_VALUES=''$YQ_VALUES' |
    .server.ingress.ingressClassName = "'$VKPR_ENV_VAULT_INGRESS'" |
    .server.ingress.hosts[0].host = "'$VKPR_ENV_VAULT_DOMAIN'"
  '
  if [[ $VKPR_ENV_SECURE == true ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .server.ingress.annotations.["'kubernetes.io/tls-acme'"] = "'true'" |
      .server.ingress.tls[0].hosts[0] = "'$VKPR_ENV_VAULT_DOMAIN'" |
      .server.ingress.tls[0].secretName = "'vault-cert'"
    '
  fi

  if [[ $VKPR_ENV_VAULT_MODE == "raft" ]]; then
  YQ_VALUES=''$YQ_VALUES' |
    .server.ha.raft.enabled = true
  '
    echo 'storage "raft" {
  path = "/vault/data"
  performance_multiplier = 1
}' >> $VKPR_VAULT_CONFIG
    else
    echo 'storage "consul" {
  path = "vault"
  address = "consul-consul-server.vkpr.svc.cluster.local:8500"
}' >> $VKPR_VAULT_CONFIG
  fi
  kubectl create secret generic vault-storage-config -n $VKPR_K8S_NAMESPACE --from-file=$VKPR_VAULT_CONFIG
}

installVault() {
  local YQ_VALUES='.global.enabled = true'
  settingVault
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_VAULT_VALUES" \
  | $VKPR_HELM upgrade -i --version "$VKPR_VAULT_VERSION" \
      --namespace $VKPR_K8S_NAMESPACE --create-namespace \
      --wait -f - vault hashicorp/vault
}

#unsealVault() {
#  sleep 30
#  for i in 0 1 2; do
#    $VKPR_KUBECTL exec -it vault-${i} -n $VKPR_K8S_NAMESPACE -- vault operator init > keys-${i}.txt
#    for j in 1 2 3 4 5; do
#      local VAULT_UNSEAL_KEY=$(cat keys-${i}.txt | head -n${j} | awk 'END{print $NF}')
#      if [[ $j -ge 4 ]]; then
#        echoColor "red" "Keys from pod vault-${i}"
#        cat keys-${i}.txt | head -n7
#        sleep 5
#        break
#      fi
#      $VKPR_KUBECTL exec -it vault-${i} -n $VKPR_K8S_NAMESPACE -- /bin/sh -c "vault operator unseal $VAULT_UNSEAL_KEY"
#    done
#  done
#  rm -rf keys-*.txt
#}