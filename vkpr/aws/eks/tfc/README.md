# VKPR aws eks tfc

## Description

Fork and setup the GitOps Repo in your Gitlab, using Terraform Cloud as Backend to save the Terraform state.
Commands#

Interactive inputs:

```
vkpr aws eks tfc [flags]
```

Non-interactive without setting values or using ```VKPR Values```:

```
vkpr aws eks tfc --default
```

## Parameters

```
  --default                         Set all values with default
  --terraformcloud_api_token        Specifies your Terraform Cloud Token
  --terraformcloud_email            Specifies your Terraform Cloud Email
```

## Setting Credentials manually

### Terraform Cloud

```
rit set credential --provider="terraformcloud" --fields="token,email" --values="your-token,your-email"
```

## Values File Parameters

```yaml
vkpr.yaml
```
```yaml
global:
  aws:                  <Object>
    eks:
      clusterName:      <String>
      version:          <String>
      nodes:
        instaceType:    <String>
        quantitySize:   <Integer>
        capacityType:   <String>
```
