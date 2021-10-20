# Description

Fork the project from [Gitops EKS](https://gitlab.com/vkpr/aws-eks) and run the pipeline to build the terraform config.

## Commands

Interactive inputs:

```bash
vkpr aws eks up
```

Non-interactive:

```bash
rit set credential --fields="accesskeyid,secretaccesskey" --provider="aws" --values="<your-access-key-id>,<your-secret-access-key>"
rit set credential --fields="token,username" --provider="gitlab" --values="<your-gitlab-token>,<your-gitlab-username>"
vkpr aws eks up --aws_region="us-east-1"
```

```bash
vkpr aws eks up --default
```

## Parameters

```bash
  --aws_region= Define the region to create the EKS. Default: us-east-1
  --default= Set all values with default.
```

## Globals File Parameters

```yaml
global:
  aws:
    eks:
      aws_region: <String>
```
