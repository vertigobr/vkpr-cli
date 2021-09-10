# Description

Install nginx-ingress controller into cluster. Uses [ingress-nginx](https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx) Helm chart.

## Command

```bash
rit vkpr ingress install
```

### Content installed on the Cluster

- Deployment
- Service
- Daemonset
- Secret (certificate)
- ConfigMap
- Job
- ClusterRole
- Role
- RoleBinding
- ServiceAccount
- ValidatingWebhookConfiguration
