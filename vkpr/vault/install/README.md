# VKPR vault install

## Description

Install Vault into cluster. For more information about Vault, click [here.](https://www.vaultproject.io/)

## Commands

Interactive inputs:

```
  vkpr vault install [flags]
```

Non-interactive without setting values or using ```VKPR Values```:

```
  vkpr vault install --default
```

## Parameters

```
  --default           Set all values with default.
  --domain            Define the domain used by the vault UI.   Default: localhost
  --secure            Specifies if the application will have HTTPS.    Default: false
  --vault_mode        Specifies the Vault storage mode.    Default: raft   Allowed Values: "raft", "consul"
  --vault_auto_unseal Enable to Auto Unseal the Vault with a Cloud provider.    Default: false    Allowed Values: "false", "aws", "azure"
    --aws_access_key     Specifies the AWS Access Key Credential.
    --aws_kms_endpoint   Specifies the AWS KMS Endpoint.
    --aws_kms_key_id     Specifies the AWS KMS ID.
    --aws_region         Specifies the AWS Region to set the environment.
    --aws_secret_key     Specifies the AWS Secret Key Credential.
    --azure_client_id                   Specifies the Azure Client ID.
    --azure_client_secret               Specifies the Azure Client Secret.
    --azure_tenant_id                   Specifies the Azure Tenant ID.
    --vault_azurekeyvault_key_name      Specifies the Azure Key Vault Key Name.
    --vault_azurekeyvault_vault_name    Specifies the Azure Key Vault Name.
```
## Setting Provider credentials manually

### AWS

```
  rit set credential --provider="aws" --fields="accesskeyid,secretaccesskey,region,kmskeyid,kmsendpoint" --values="your-accesskey,your-secretaccess,your-region,your-kmskeyid,your-kmsendpoint"
```

## Azure

```
  rit set credential --provider="azure" --fields="azuretenantid,azureclientid,azureclientsecret,vaultazurekeyvaultvaultname,vaultazurekeyvaultkeyname" --values="your-azuretenantid,your-azureclientid,your-azureclientsecret,your-vaultazurekeyvaultvaultname,your-vaultazurekeyvaultkeyname,"
```

## Values File Parameters

```yaml
vkpr.yaml
```
```yaml
global:
  domain:               <String>
  secure:               <Boolean>
  vault:
    namespace:          <String>
    ingressClassName:   <String>
    storageMode:        <String>
    autoUnseal:         <Boolean>
    helmArgs:           <Object>
```
