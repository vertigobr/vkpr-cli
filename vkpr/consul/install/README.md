# VKPR consul install

## Description

Install Consul into cluster. For more information about Consul, click [here.](https://www.consul.io/)

## Commands

Interactive inputs:

```
  vkpr consul install [flags]
  ```

Non-interactive without setting values or using ```VKPR Values```:

```
  vkpr consul install --default
```

> caution: Consul will always be installed in HA (High Availability), it is recommended that the cluster has at least 3 Nodes.

## Parameters

```
  --default           Set all values with default.
  --domain            Define the domain used by the Consul UI.   Default: localhost
  --secure            Specifies if the application will have HTTPS.    Default: false
```

## Values File Parameters

```yaml
vkpr.yaml
```
```yaml
global:
  domain:               <String>
  secure:               <Boolean>
  consul:
    namespace:          <String>
    ingressClassName:   <String>
    metrics:            <Boolean>
    helmArgs:           <Object>
```
