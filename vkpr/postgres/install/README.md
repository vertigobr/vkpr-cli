# Description

Install Postgres into cluster. Uses [postgresql](https://artifacthub.io/packages/helm/bitnami/postgresql) Helm chart.

## Commands

Interactive input:

```bash
vkpr postgres install
```

Non-interactive:

```bash
rit set credential --provider="postgres" --fields="password" --values="<your-postgres-password>"
vkpr postgres install
```

### Content installed on the Cluster

- Statefulset
- Service
- Secret
- PV and PVC
