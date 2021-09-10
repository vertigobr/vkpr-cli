# Description

Install keycloak into cluster. Uses [keycloak](https://artifacthub.io/packages/helm/bitnami/keycloak) Helm chart.

## Commands

Interactive inputs:

```bash
vkpr keycloak install
```

Non-interactive:

```bash
vkpr keycloak install --domain="keycloak.localhost" \
                      --secure=false \
                      --admin_user="admin" \
                      --admin_password="vkpr123"
```

Non-interactive without setting values:

```bash
vkpr keycloak install --default
```

## Parameters

```bash
  --domain= Define the domain of whoami. Default: keycloak.localhost
  --secure= Define https on the keycloak. Default: false
  --admin_user= Define RBAC Admin user on the keycloak. Default: admin
  --admin_password= Define RBAC Admin password keycloak. Default: vkpr123
  --default= Set all values with default.
```

**Note:** Require credential of Password Postgres to create the postgres

## Globals File Parameters

```yaml
global:
  keycloak:
    domain: <String>
    secure: <Bool>
    admin_user: <String>
    admin_password: <String>
```

### Content installed on the Cluster

- Statefulset
- Service
- Ingress
- Secret (certificate)
- ConfigMap
- Job
- Role
- RoleBinding
- ServiceAccount
