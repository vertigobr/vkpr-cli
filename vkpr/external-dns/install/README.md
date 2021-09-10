# Description

Install external-dns into cluster. Uses [external-dns](https://artifacthub.io/packages/helm/bitnami/external-dns) Helm chart.

## Commands

Interactive inputs:

```bash
vkpr external-dns install
```

Non-interactive:

```bash
rit set credential --provider="digitalocean" --fields="token" --values="<your-digitalocean-token>"
vkpr external-dns install --provider="digitalocean"
```

Non-interactive without setting values:

```bash
vkpr external-dns install --default
```

## Parameters

```bash
  --provider= Define the provider from external-dns. Default: digitalocean
  --default= Set all values with default.
```

## Globals File Parameters

```yaml
global:
  external-dns:
    provider: <String>
```

### Content installed on the Cluster

- Deployment
- Service
- Secret (certificate)
- Job
- ServiceAccount
- ClusterRole
- ClusterRoleBinding
