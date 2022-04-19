# VKPR infra start

## Description

Create a configurable k3d cluster to test the applications.

# Commands

Interactive inputs:

```
  vkpr infra start [flags]
```

Non-interactive without setting values or using ```VKPR Values```:

```
  vkpr infra start --default
```

## Parameters

```
  --http_port         Define HTTP port used by k3d.           Default: 8000
  --https_port        Define HTTPS port used by k3d.          Default: 8001
  --enable_traefik    Set traefik as the default ingress.     Default: false
  --default           Set all values with default.

```

## Values File Parameters


```yaml
vkpr.yaml
```
```yaml
global:
  infra:
    httpPort:  <Integer>
    httpsPort: <Integer>
    traefik:
      enabled:  <Boolean>
    resources:
      servers:  <Integer>
      agents:   <Integer>
```
