# VKPR kong install

## Description

Install Kong Gateway into cluster. For more information about Kong, click [here.](https://docs.konghq.com/gateway/)

# Commands

Interactive inputs:

```
  vkpr kong install [flags]
```

Non-interactive without setting values or using ```VKPR Values```:

```
  vkpr kong install --default
```

## Parameters

```
  --default           Set all values with default.
  --domain            Define the domain used by the kong.          Default: localhost
  --secure            Specifies if the application will have HTTPS.    Default: false
  --kong_mode         Specifies the type of Kong Deployment.      Default: dbless    Allowed values: "dbless", "standard", "hybrid"
  --enterprise        Specifies if the Kong will be using Enterprise License.   Default: false
    --license         Specifies the Kong Enterprise License.
  --rbac_password     Define RBAC Super Admin Kong password.       Default: vkpr123
  --HA                Specifies if the application will have High Availability.   Default: false
```

## Setting Postgresql credentials

### Postgresql
 ```
   rit set credential --provider="postgres" --fields="password" --values="your-password"
 ```
 
 ## Values File Parameters
 
```yaml
  vkpr.yaml
```
```yaml
 global:
  domain:               <String>
  secure:               <Boolean>
  kong:
    namespace:          <String>
    mode:               <String>
    rbac:
      adminPassword:    <String>
    HA:                 <Boolean>
    metrics:            <Boolean>
    helmArgs:           <Object>
```
 
