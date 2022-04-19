# VKPR ingress install

## Description#

Install nginx-ingress controller into cluster. For more information about nginx-ingress controller, click [here.](https://kubernetes.github.io/ingress-nginx/deploy/)

## Commands

Interactive inputs:

```
  vkpr ingress install [flags]
```

Non-interactive without setting values or using ```VKPR Values```:

```
  vkpr ingress install --default
```

## Parameters

```
  --default       Set all values with default.
  --lb_type       Define the Loadbalancer type in AWS. Default: "Classic" Allowed values: "Classic", "NLB"
```

## Values File Parameters

```yaml
vkpr.yaml
```
```yaml
global:
  ingress:
    namespace:   <String>
    loadBalancerType:   <String>
    metrics:    <Boolean>
    helmArgs:   <Object>
```
