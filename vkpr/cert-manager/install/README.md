# VKPR cert-manager install

## Description

Install cert-manager into cluster. For more information about cert-manager, click here.

## Commands

Interactive inputs:

```
  vkpr cert-manager install [flags]
```

Non-interactive without setting values or using ```VKPR Values```:

```
  vkpr cert-manager install --default
```
# Parameters

```
  --default                Set all values with default
  --email                  Inform your email to be used as a contact with the CA
  --issuer                 Specify the issuer to create the certificates. In general, is used Lets Encrypted as CA    Default: "staging"    Allowed values: "staging", "production", "custom-acme"
  --issuer_solver          Specify the type of Challenge used to validate the URL    Default: "HTTP01"    Allowed values: "HTTP01", "DNS01"
    --cloud_provider       Specify which cloud-provider will be used to record the DNS TXT record if issuer_solver be `DNS01`   Allowed values: "aws", "digitalocean", "custom-acme"
      --aws_access_key          Specifies the AWS Access Key Credential
      --aws_secret_key          Specifies the AWS Secret Key Credential
      --aws_region              Specifies the AWS Region to set the env
      --aws_hostedzone_id       Specifies the Hostedzone ID from the domain in Route53
      --do_token                Specifies the Digital Ocean API Token
```

## Values File Parameters

```yaml
vkpr.yaml
```
```yaml
global:
  cert-manager:
    email:         <String>
    solver:        <String>
    provider:      <String>
    ingress:       <String>
    helmArgs:      <Object>
```

## Setting Cloud Providers credentials manually

## AWS

```
  rit set credential --provider="aws" --fields="accesskeyid,secretaccesskey,region" --values="your-accesskey,your-secretaccess,your-region"
```

## Digital Ocean

```
  rit set credential --provider="digitalocean" --fields="token" --values="your-api-token"
```
