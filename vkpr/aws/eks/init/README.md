# VKPR aws eks init

## Description

Fork and setup the[GitOps Repo](https://gitlab.com/vkpr/aws-eks) in your Gitlab, using Gitlab Backend to save the Terraform state.

## Commands

Interactive inputs:

```bash
vkpr aws eks init [flags]
```

Non-interactive without setting values or using ```VKPR Values```:

```bash
vkpr aws eks init --default
```

## Parameters

```bash
  --default                         Set all values with default
  --aws_access_key                  Specifies the AWS Access Key Credential
  --aws_secret_key                  Specifies the AWS Secret Key Credential
  --aws_region                      Specifies the AWS Region to set the environment
  --eks_cluster_name                Specifies the EKS Cluster name    Default: "eks-sample"
  --eks_capacity_type               Specifies the EKS Node Group capacity type    Default: "ON_DEMAND"    Allowed values: "ON_DEMAND", "SPOT"
  --eks_cluster_node_instance_type  Specifies the Node instance type    Default: "t3.small"
  --eks_cluster_size                Specifies the number of Nodes   Default: "1"
  --eks_k8s_version                 Specifies the Kubernetes Version    Default: "1.20"
  --terraform_state                 Specifies where you want to store the TF state    Default: "Gitlab"   Allowed values: "Gitlab", "Terraform Cloud"
  --gitlab_token                    Specifies your Gitlab Access-Token
  --gitlab_username                 Specifies your Gitlab Username
  --tf_cloud_token                  Specifies your Terraform Cloud Token.
```

## Setting Credentials manually

## Gitlab
```
rit set credential --provider="gitlab" --fields="token,username" --values="your-token,your-username"
```

## Terraform Cloud
```
rit set credential --provider="terraformcloud" --fields="token" --values="your-token"
```

## AWS
```
rit set credential --provider="aws" --fields="accesskeyid,secretaccesskey,region" --values="your-accesskey,your-secretaccess,your-region"
```

## Values File Parameters

```yaml
vkpr.yaml
```
```yaml
global:
  aws:
    eks:                <Object>
      clusterName:      <String>
      version:          <String>
      nodes:            <Object>
        instaceType:    <String>
        quantitySize:   <Integer>
        capacityType:   <String>
```
