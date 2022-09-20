#!/usr/bin/env bash

runFormula() {

  [[ "$APLICATION_PATH" == "" ]] && APLICATION_PATH=$CURRENT_PWD
  validateInputs

  startInfos

  local DIR_NAME="vkpr-logs-$APLICATION_NAME-$(date -I)" \
        LOGS_PATH="$APLICATION_PATH/$DIR_NAME" 

  mkdir "$LOGS_PATH"

  listPods 
  logPods
  describeAplication
  describeNodes
  valuesAplication

  cd $LOGS_PATH
  zip -r $DIR_NAME.zip $DIR_NAME/
  # rm -r $LOGS_PATH/
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Info Dump Routine"
  boldNotice "Aplication Name: $APLICATION_NAME"
  boldNotice "Aplication Path: $APLICATION_PATH"
  boldNotice "Aplication Namespace: $APLICATION_NAMESPACE"
  bold "=============================="
}

validateInputs() {
  # Local App Values
  validateInfoDumpPath "$APLICATION_PATH"
  validateInfoDumpNamespace "$APLICATION_NAMESPACE"
  validateInfoDumpName "$APLICATION_NAME"
}

logPods(){
  declare -i COUNT=0
  for pod in $($VKPR_KUBECTL get pods -l app.kubernetes.io/instance=$APLICATION_NAME,app.kubernetes.io/managed-by=vkpr -A --ignore-not-found  | awk 'NR>1{print $2}'); do
    $VKPR_KUBECTL logs $pod -n $APLICATION_NAMESPACE --all-containers | tac > $LOGS_PATH/vkpr-logs-pod-$pod-$COUNT.txt
    ((COUNT++))
  done
}

listPods(){
  $VKPR_KUBECTL get pods -l app.kubernetes.io/instance=$APLICATION_NAME,app.kubernetes.io/managed-by=vkpr -A --ignore-not-found > $LOGS_PATH/"vkpr-list-pods".txt
}

describeAplication(){
  declare -i COUNT=0
  for type in pod svc ingress; do
    for resourse in $($VKPR_KUBECTL get $type -n $APLICATION_NAMESPACE --ignore-not-found  | awk 'NR>1{print $1}'); do
      if [[ "$resourse" == *"$APLICATION_NAME"* ]]; then
        $VKPR_KUBECTL describe "$type/$resourse" -n $APLICATION_NAMESPACE > $LOGS_PATH/"vkpr-describe-$type-$resourse-$COUNT".txt
        ((COUNT++))
      fi
    done
    COUNT=0
  done
}

describeNodes(){
  declare -i COUNT=0
  for node in $($VKPR_KUBECTL get node -n $APLICATION_NAMESPACE --ignore-not-found  | awk 'NR>1{print $1}'); do
    $VKPR_KUBECTL describe "node/$node" -n $APLICATION_NAMESPACE > $LOGS_PATH/"vkpr-describe-node-$node-$COUNT".txt
    ((COUNT++))
  done
  COUNT=0
}

valuesAplication(){        
  $VKPR_HELM get values $APLICATION_NAME -n $APLICATION_NAMESPACE > $LOGS_PATH/"vkpr-values-$APLICATION_NAME".txt
}

