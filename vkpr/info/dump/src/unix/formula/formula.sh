#!/usr/bin/env bash

runFormula() {

  [[ "$APPLICATION_PATH" == "" ]] && APPLICATION_PATH=$CURRENT_PWD
  validateInputs

  local DIR_NAME="vkpr-logs-$APPLICATION_NAME-$(date -I)" 
  
  HELM_FLAG="-A"
  [[ "$VKPR_ENVIRONMENT" == "okteto" ]] && HELM_FLAG=""
  APPLICATION_NAMESPACE=$($VKPR_HELM ls -o=json $HELM_FLAG |\
                     $VKPR_JQ -r ".[] | select(.name | contains(\"$APPLICATION_NAME\")) | .namespace" |\
                     head -n1)
                        
  # Making directories to add logs..
  startInfos
  checkApplication
  mkdir -p "$APPLICATION_PATH/$DIR_NAME"


  # Extracting logs..
  listPods
  logPods
  describeApplication
  describeNodes
  valuesApplication

  # Compressing Logs..
  cd $APPLICATION_PATH
  zip -r $DIR_NAME.zip $DIR_NAME/*
  rm -r "$APPLICATION_PATH/$DIR_NAME"
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Info Dump Routine"
  boldNotice "Application Name: $APPLICATION_NAME"
  boldNotice "Application Path: $APPLICATION_PATH"
  boldNotice "Application Namespace: $APPLICATION_NAMESPACE"
  bold "=============================="
}

validateInputs() {
  # Local App Values
  validateInfoDumpPath "$APPLICATION_PATH"
  validateInfoDumpName "$APPLICATION_NAME"
}

checkApplication(){
  if $($VKPR_HELM list -n $APPLICATION_NAMESPACE | awk 'NR>1{print $1}'| grep -q "$APPLICATION_NAME") ; then
    boldInfo "Starting log extraction process..."
  else
    error "Application not found or not specified correctly, please check the application name."
    exit
  fi
}

logPods(){
  declare -i COUNT=0
  for pod in $($VKPR_KUBECTL get pods -l app.kubernetes.io/instance=$APPLICATION_NAME,app.kubernetes.io/managed-by=vkpr -A --ignore-not-found  | awk 'NR>1{print $2}'); do
    $VKPR_KUBECTL logs $pod -n $APPLICATION_NAMESPACE --all-containers | tac > $APPLICATION_PATH/$DIR_NAME/vkpr-logs-pod-$pod-$COUNT.txt
    ((COUNT++))
  done
}

listPods(){
  $VKPR_KUBECTL get pods -l app.kubernetes.io/instance=$APPLICATION_NAME,app.kubernetes.io/managed-by=vkpr $HELM_FLAG --ignore-not-found > $APPLICATION_PATH/$DIR_NAME/"vkpr-list-pods".txt
}

describeApplication(){
  declare -i COUNT=0
  for type in pod svc ingress; do
    for resourse in $($VKPR_KUBECTL get $type -n $APPLICATION_NAMESPACE --ignore-not-found  | awk 'NR>1{print $1}'); do
      if [[ "$resourse" == *"$APPLICATION_NAME"* ]]; then
        $VKPR_KUBECTL describe "$type/$resourse" -n $APPLICATION_NAMESPACE > $APPLICATION_PATH/$DIR_NAME/"vkpr-describe-$type-$resourse-$COUNT".txt
        ((COUNT++))
      fi
    done
    COUNT=0
  done
}

describeNodes(){
  declare -i COUNT=0
  for node in $($VKPR_KUBECTL get node -n $APPLICATION_NAMESPACE --ignore-not-found  | awk 'NR>1{print $1}'); do
    $VKPR_KUBECTL describe "node/$node" -n $APPLICATION_NAMESPACE > $APPLICATION_PATH/$DIR_NAME/"vkpr-describe-node-$node-$COUNT".txt
    ((COUNT++))
  done
  COUNT=0
}

valuesApplication(){        
  $VKPR_HELM get values $APPLICATION_NAME -n $APPLICATION_NAMESPACE > $APPLICATION_PATH/$DIR_NAME/"vkpr-values-$APPLICATION_NAME".txt
}