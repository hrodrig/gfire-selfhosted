# Helm chart index (gfire)

This **`gh-pages`** branch is the **Helm chart repository** served at  
**https://hrodrig.github.io/gfire-selfhosted/** for [gfire](https://github.com/hrodrig/gfire).

| File | Role |
|------|------|
| **`index.yaml`** | Chart index — updated by [helm/chart-releaser](https://github.com/helm/chart-releaser) when a **`v*`** tag is pushed (with chart changes under `run/kubernetes/helm/`). |
| **`index.html`** | Human-readable landing for the same URL (optional; Helm uses **`index.yaml`** only). |
| **`.nojekyll`** | Disables Jekyll so `index.yaml` is served as-is. |

Sources and operator documentation: **[gfire-selfhosted](https://github.com/hrodrig/gfire-selfhosted)**.

## Quick start

```bash
helm repo add gfire https://hrodrig.github.io/gfire-selfhosted
helm repo update
helm install gfire gfire/gfire -n gfire --create-namespace -f my-values.yaml
```

Use **`helm show values gfire/gfire`** after **`helm repo update`** to build **`my-values.yaml`**.
