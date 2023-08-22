# VKPR nginx install

## Description#

Install nginx controller into cluster. For more information about nginx controller, click [here.](https://kubernetes.github.io/ingress-nginx/deploy/)

## Commands

Interactive inputs:

```
  vkpr nginx install [flags]
```

Non-interactive without setting values or using ```VKPR Values```:

```
  vkpr nginx install --default
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
  nginx:
    namespace:   <String>
    loadBalancerType:   <String>
    metrics:    <Boolean>
    helmArgs:   <Object>
```
