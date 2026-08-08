# Kubernetes manifests

Raw manifests are **not** the primary path yet.

Use the Helm chart under [`../helm/gfire/`](../helm/gfire/) when it lands (same pattern as [pgwd-selfhosted](https://github.com/hrodrig/pgwd-selfhosted): prefer `helm template` over hand-maintained YAML).

Until then, Compose minimal is the supported cluster-adjacent lab path.
