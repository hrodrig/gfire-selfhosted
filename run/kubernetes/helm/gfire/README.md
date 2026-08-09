# Helm chart: gfire

Deploys the **gfire** engine image (`ghcr.io/hrodrig/gfire`) as peer replicas with shared external Postgres.

## Install (sketch)

```bash
# Create DSN secret first (recommended)
kubectl create secret generic gfire-postgres \
  --from-literal=dsn='postgres://gfire:gfire@postgres:5432/gfire?sslmode=disable'

helm upgrade --install gfire ./run/kubernetes/helm/gfire \
  --set postgres.existingSecret=gfire-postgres \
  --set image.tag=v1.0.3
```

## Values highlights

| Key | Default | Notes |
|-----|---------|-------|
| `replicaCount` | `2` | Peers; `GFIRE_SERVER_SERVER_ID` = pod name |
| `image.tag` | `v1.0.3` | Pin to app release |
| `env.storageBackend` | `postgres` | External DB required |
| `postgres.existingSecret` | `""` | Preferred over inline `postgres.dsn` |
| `env.authEnabled` | `"false"` | Set `"true"` + auth secret for Bearer |

## Validate

```bash
make release-check   # helm lint + template + kubeconform (+ Compose)
```

Console overlay (SPA + BFF) is a later chart/values band (`GSH-032`).
