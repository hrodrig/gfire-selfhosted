# Kubernetes manifests

Raw YAML is **not** the primary path.

Prefer the Helm chart:

```bash
helm template gfire ../helm/gfire \
  --set postgres.existingSecret=gfire-postgres \
  > example-rendered.yaml
```

Review before `kubectl apply`. Values in [`../helm/gfire/values.yaml`](../helm/gfire/values.yaml) are the source of truth.
