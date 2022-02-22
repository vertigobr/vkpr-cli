# VKPR external-dns install

## Description

Install external-dns into cluster. For more information about external-dns, click [here.](https://github.com/kubernetes-sigs/external-dns)

Commands

Interactive inputs:

```
  vkpr external-dns install [flags]
```

Non-interactive without setting values or using ```VKPR Values```:

```
  vkpr external-dns install [flags]
```

## Parameters

```
  --default       Set all values with default.
  --provider      Define the provider of external-dns. Default: "aws" Allowed values: "aws", "digitalocean", "powerDNS"
    --aws_access_key          Specifies the AWS Access Key Credential.
    --aws_secret_key          Specifies the AWS Secret Key Credential.
    --aws_region              Specifies the AWS Region to set the env.
    --do_token                Specifies the Digital Ocean API Token.
    --pdns_apikey             Specifies the PowerDNS API Key.
    --pdns_apiurl             Specifies the PowerDNS server URL Endpoint.
```

## Setting Provider credentials manually#

### AWS

```
  rit set credential --provider="aws" --fields="accesskeyid,secretaccesskey,region" --values="your-accesskey,your-secretaccess,your-region"
```

### Digital Ocean

```
  rit set credential --provider="digitalocean" --fields="token" --values="your-api-token"
```

### PowerDNS

```
  rit set credential --provider='powerdns' --fields="apikey" --values="your-key"
```

## Values File Parameters

```yaml
vkpr.yaml
```
```yaml
global:
  external-dns:
    namespace:  <String>
    provider:   <String>
    metrics:    <Boolean>
    powerDNS:
      apiUrl:   <String>
    helmArgs:   <Object>
```
