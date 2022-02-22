# VKPR prometheus-stack install

## Description

Install kube-prometheus-stack into cluster. For more information about prometheus-stack, click here.

Kube-prometheus-stack is a monitoring application package, containing:

*    Prometheus
*    Alert-Manager
*    Grafana
*    Kubernetes Exporters

# Commands

Interactive inputs:

```
  vkpr prometheus-stack install [flags]
```

Non-interactive without setting values or using ```VKPR Values```:

```
  vkpr prometheus-stack install --default
```

## Parameters

```
  --default           Set all values with default.
  --domain            Define the domain used by the prometheus-stack.          Default: localhost
  --secure            Specifies if the application will have HTTPS.    Default: false
  --grafana_password  Define Super Admin Grafana password.       Default: vkpr123
  --alertmanager      Enable Alert-manager to be installed.    Default: admin
    --HA                Specifies if the application will have High Availability.   Default: false
```

## Values File Parameters

```yaml
vkpr.yaml
```
```yaml
global:
  domain:               <String>
  secure:               <Boolean>
  prometheus-stack:
    namespace:          <String>
    ingressClassName:   <String>
    alertManager:
      enabled:          <Boolean>
      HA:               <Boolean>
    grafana:
      adminPassword:    <String>
      k8sExporters:
    helmArgs:           <Object>
```
