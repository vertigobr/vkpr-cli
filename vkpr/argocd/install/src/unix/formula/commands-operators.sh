#!/usr/bin/env bash

argocdSetRepo() {
  local REPO_URL=$1 \
        ARGOCD_NAMESPACE=$2 \
        GITLAB_USERNAME=$3 \
        GITLAB_TOKEN=$4

  REPO_NAME=$(echo "$REPO_URL" | awk -F "/" '{ print $NF }' | cut -d "." -f1)

  info "Connecting repository in Argocd" 
  $VKPR_KUBECTL create secret generic "${REPO_NAME}-repo" -n $ARGOCD_NAMESPACE --dry-run=client -o yaml | \
      $VKPR_YQ eval ".metadata.labels.[\"argocd.argoproj.io/secret-type\"] = \"repository\" |
                     .metadata.labels.[\"argocd.app.kubernetes.io/managed-by\"] = \"vkpr\"  |         
                     .stringData.url = \"$REPO_URL\" |
                     .stringData.username = \"$GITLAB_USERNAME\" |
                     .stringData.password = \"$GITLAB_TOKEN\" 
      " - | $VKPR_KUBECTL apply -f -
}

argocdAplicationSet (){
  local REPO_URL=$1 \
        ARGOCD_NAMESPACE=$2 \
        VKPR_APPLICATIONSET_VALUES=$3

  REPO_NAME=$(echo "$REPO_URL" | awk -F "/" '{ print $NF }' | cut -d "." -f1)

  info "Creating Applicationset in Argocd"
  $VKPR_YQ eval " .metadata.name = \"$REPO_NAME-applicationset\" |
                  .metadata.namespace = \"$ARGOCD_NAMESPACE\" |
                  .spec.generators[0].git.repoURL = \"$REPO_URL\" |
                  .spec.template.spec.source.repoURL = \"$REPO_URL\" 
  " $VKPR_APPLICATIONSET_VALUES | $VKPR_KUBECTL apply -f -
}
