# Description

Install whoami into cluster. Uses [whoami](https://artifacthub.io/packages/helm/cowboysysop/whoami) Helm chart.

## Commands

Interactive inputs:

```bash
vkpr whoami install
```

Non-interactive:

```bash
vkpr whoami install --domain="whoami.localhost" \
                    --secure=false
```

Non-interactive without setting values:

```bash
vkpr whoami install --default
```

## Parameters

```bash
  --domain= Define the domain of whoami. Default: whoami.localhost
  --secure= Define https on the whoami. Default: false
  --default= Set all values with default.
```

## Globals File Parameters

```yaml
global:
  domain: <String>
  secure: <Bool>
```

### Content installed on the Cluster

- Deployment
- Service
- Ingress
- Secret (certificate)
