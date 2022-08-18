#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Digital Ocean Credential validators
# -----------------------------------------------------------------------------

validateDigitalOceanClusterName() {
  if [[ "$1" =~ ^([A-Za-z0-9-]+)$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_DO_CLUSTER_NAME \"$1\" is invalid: VKPR_ENV_DO_CLUSTER_NAME must consist of lowercase, uppercase or '-' alphanumeric characters, (e.g. 'do-sample', regex used for validation is ^([A-Za-z0-9-]+)$)."
    exit
  fi
}

validateDigitalOceanClusterVersion() {
  if [[ "$1" =~ ^([0-9]{1}\.[0-9]{2})$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_DO_K8S_VERSION \"$1\" is invalid: VKPR_ENV_DO_K8S_VERSION must consist of a number and '.', (e.g. '1.22', regex used for validation is ^([0-9]{1}\.[0-9]{2})$."
    exit
  fi
}

validateDigitalOceanClusterRegion() {
  if [[ "$1" =~ ^(nyc1|nyc2|sfo1)$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_DO_CLUSTER_REGION \"$1\" is invalid: VKPR_ENV_DO_CLUSTER_REGION must consist of nyc1, nyc2 or sfo1."
    exit
  fi
}

validateDigitalOceanInstanceType() {
  if [[ "$1" =~ ^([a-z]{1}\-[a-z0-9]{5}\-[a-z0-9]{3})$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_DO_CLUSTER_NODES_INSTANCE_TYPE \"$1\" is invalid: VKPR_ENV_DO_CLUSTER_NODES_INSTANCE_TYPE must consist of lowercase and alphanumeric characters, (e.g. 's-2vcpu-2gb', regex used for validation is ^([a-z]{1}\-[a-z0-9]{5}\-[a-z0-9]{3})$)."
    exit
  fi
}

validateDigitalOceanClusterSize() {
  if [[ "$1" =~ ^([0-9])$ ]]; then
    return
  else
    error "The value used for VKPR_ENV_DO_CLUSTER_QUANTITY_SIZE \"$1\" is invalid: VKPR_ENV_DO_CLUSTER_QUANTITY_SIZE must consist of number, (e.g. '1', regex used for validation is ^([0-9])$."
    exit
  fi
}

validateDigitalOceanApiToken() {
  if [[ "$1" =~ ^([a-z]+_v1_[A-Za-z0-9]{64})$ ]]; then
    return
  else
    error "The value used for DO_TOKEN \"$1\" is invalid: DO_TOKEN must consist of lowercase, uppercase or '-' alphanumeric characters, (regex used for validation is ^([a-z]+_v1_[A-Za-z0-9]{64})$.)"
    exit
  fi
}
