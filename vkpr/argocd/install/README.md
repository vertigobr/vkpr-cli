# VKPR argocd install

## Description

Install ArgoCD into cluster. For more information about ArgoCD, click [here](https://argo-cd.readthedocs.io/en/stable/)

## Commands

Interactive inputs:

```
vkpr argocd install [flags]
```

Non-interactive without setting values or using ```VKPR Values```:

```
vkpr argocd install --default
```
## Parameters

```
  --default           Set all values with default
  --domain            Define the domain used by the ArgoCD   Default: "localhost"
  --secure            Specifies if the application will have HTTPS   Default: "false"
  --admin_password    Define Super Admin ArgoCD password   Default: "vkpr123"
  --HA                Specifies if the application will have High Availability   Default: "false"
```

## Values File Parameters

```yaml
vkpr.yaml
```
```yaml
global:
  domain:   <String>
  secure:   <Boolean>
  argocd:
    namespace:   <String>
    ingressClassName:   <String>
    HA:   <Boolean>
    metrics:    <Boolean>
    addons:
      applicationset:   <Boolean>
    helmArgs:   <Object>
 ```
