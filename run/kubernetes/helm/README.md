# Helm

Chart: [`gfire/`](./gfire/) — engine Deployment + Service (+ optional Secrets).

```bash
helm lint run/kubernetes/helm/gfire
helm template lab run/kubernetes/helm/gfire \
  --set postgres.dsn='postgres://gfire:gfire@postgres:5432/gfire?sslmode=disable'
```

Routing: Host / Ingress rewrite at the edge — apps keep root paths (`/v1`, `/healthz`). See design §8.

Publish: chart-releaser on repo tags `v*` (GitHub Pages `gh-pages`). Console overlay = later band.
