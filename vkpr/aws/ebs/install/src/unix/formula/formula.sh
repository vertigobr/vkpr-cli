#!/usr/bin/env bash
runFormula() {
  
startInfos() {
  bold "=============================="
  boldInfo "VKPR Install AWS EBS CSI Driver"
  boldNotice "EKS-Cluster: $EKS_CLUSTERNAME"
  bold "=============================="
}

  # Addons Values

installaddonebs(){
eksctl utils associate-iam-oidc-provider --region=$AWS_REGION --cluster=$EKS_CLUSTERNAME --approve

eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster $EKS_CLUSTERNAME \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --role-only \
  --role-name AmazonEKS_EBS_CSI_DriverRole_$EKS_CLUSTERNAME

eksctl create addon --name aws-ebs-csi-driver --cluster $EKS_CLUSTERNAME --service-account-role-arn arn:aws:iam::$AWS_ACCOUNTID:role/AmazonEKS_EBS_CSI_DriverRole_$EKS_CLUSTERNAME --force

 }
installaddonebs
}
