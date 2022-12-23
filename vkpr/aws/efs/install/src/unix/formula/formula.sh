#!/usr/bin/env bash

runFormula() {

  startInfos

startInfos() {
  bold "=============================="
  boldInfo "VKPR Loki Install Routine"
  boldNotice "Namespace: $VKPR_ENV_LOKI_NAMESPACE"
  bold "=============================="
}
InstallPolicy(){
  curl -o iam-policy-example.json https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/docs/iam-policy-example.json
  aws iam create-policy \
    --policy-name AmazonEKS_EFS_CSI_Driver_Policy \
    --policy-document file://iam-policy-example.json
}
  helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
  helm repo update

  case $AWS_REGION in
    us-east-1)
    CONTEINER_IMAGE_EFS="602401143452.dkr.ecr.us-east-1.amazonaws.com" 
    ;;
    us-east-2)
    CONTEINER_IMAGE_EFS="602401143452.dkr.ecr.us-east-2.amazonaws.com" 
    ;;
    us-west-1)
    CONTEINER_IMAGE_EFS="602401143452.dkr.ecr.us-west-1.amazonaws.com" 
    ;;
    us-west-2)
    CONTEINER_IMAGE_EFS="602401143452.dkr.ecr.us-west-2.amazonaws.com"  
    ;;
    af-south-1)
    CONTEINER_IMAGE_EFS="877085696533.dkr.ecr.af-south-1.amazonaws.com" 
    ;;
    ap-east-1)
    CONTEINER_IMAGE_EFS="800184023465.dkr.ecr.ap-east-1.amazonaws.com"  
    ;;
    ap-southeast-3)
    CONTEINER_IMAGE_EFS="296578399912.dkr.ecr.ap-southeast-3.amazonaws.com"  
    ;;
    ap-south-1)
    CONTEINER_IMAGE_EFS="602401143452.dkr.ecr.ap-south-1.amazonaws.com" 
    ;;
    ap-northeast-3)
    CONTEINER_IMAGE_EFS="602401143452.dkr.ecr.ap-northeast-3.amazonaws.com" 
    ;;
    ap-northeast-2)
    CONTEINER_IMAGE_EFS="602401143452.dkr.ecr.ap-northeast-2.amazonaws.com"  
    ;;
    ap-northeast-1)
    CONTEINER_IMAGE_EFS="602401143452.dkr.ecr.ap-northeast-1.amazonaws.com" 
    ;;
    ap-southeast-2)
    CONTEINER_IMAGE_EFS="602401143452.dkr.ecr.ap-southeast-2.amazonaws.com"  
    ;;
    ap-southeast-1)
    CONTEINER_IMAGE_EFS="602401143452.dkr.ecr.ap-southeast-1.amazonaws.com"  
    ;;
    ca-central-1)
    CONTEINER_IMAGE_EFS="602401143452.dkr.ecr.ca-central-1.amazonaws.com" 
    ;;
    eu-central-1)
    CONTEINER_IMAGE_EFS="602401143452.dkr.ecr.eu-central-1.amazonaws.com" 
    ;;
    eu-west-1)
    CONTEINER_IMAGE_EFS="602401143452.dkr.ecr.eu-west-1.amazonaws.com" 
    ;;
    eu-west-2)
    CONTEINER_IMAGE_EFS="602401143452.dkr.ecr.eu-west-2.amazonaws.com" 
    ;;
    eu-south-1)
    CONTEINER_IMAGE_EFS="590381155156.dkr.ecr.eu-south-1.amazonaws.com" 
    ;;
    eu-west-3)
    CONTEINER_IMAGE_EFS="602401143452.dkr.ecr.eu-west-3.amazonaws.com" 
    ;;
    me-south-1)
    CONTEINER_IMAGE_EFS="558608220178.dkr.ecr.me-south-1.amazonaws.com" 
    ;;
    me-central-1)
    CONTEINER_IMAGE_EFS="759879836304.dkr.ecr.me-central-1.amazonaws.com" 
    ;;
    sa-east-1)
    CONTEINER_IMAGE_EFS="602401143452.dkr.ecr.sa-east-1.amazonaws.com" 
    ;;
  esac

  helm upgrade -i aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
    --namespace kube-system \
    --set image.repository=${CONTEINER_IMAGE_EFS} \
    --set controller.serviceAccount.create=false \
    --set controller.serviceAccount.name=efs-csi-controller-sa

}