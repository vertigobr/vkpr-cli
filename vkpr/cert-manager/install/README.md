# Description

Install cert-manager into cluster. Uses [cert-manager](https://artifacthub.io/packages/helm/cert-manager/cert-manager) Helm chart.

## Commands

Interactive inputs:

```bash
vkpr cert-manager install
```

Non-interactive:

```bash
rit set credential --provider="digitalocean" --fields="token" --values="<your-digitalocean-token>"
vkpr cert-manager install --email="your-email@your-provider.com"
```

## Parameters

```bash
  --email= Define the email to use on Lets Encrypt. Default: none
```

## Globals File Parameters

```yaml
global:
  cert-manager:
    email: <String>
```

### Content installed on the Cluster

- Deployment
- Service
- Secret (certificate)
- ServiceAccount
- MutatingWebhookConfiguration
- ValidatingWebhookConfiguration
- CRDS
