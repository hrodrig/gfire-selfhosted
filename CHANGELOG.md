# Changelog

All notable changes to **gfire-selfhosted** (deployment manifests, docs, and tooling for this repository only) are documented here. For the **gfire** application, see [gfire CHANGELOG](https://github.com/hrodrig/gfire/blob/main/CHANGELOG.md).

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.1] - 2026-08-08

### Added

- **Compose console** (`GSH-030`): `run/docker-compose/console/` — three gfire peers (`gfire-1`…`gfire-3`), gfireui-backend, SPA, dual `postgres:18.4-bookworm`; `extract-gfireui-migrations.sh`.
- Console `.env.example` with `GFIRE_STACK_*` / `GFIRE_*` / `GFIREUI_*` / `GFIREUI_BACKEND_*` prefixes and bootstrap admin (`GSH-031`).
- **Helm chart** `run/kubernetes/helm/gfire/` (`GSH-020`–`024`): engine Deployment/Service, Postgres DSN Secret, optional auth Secret, peer `server_id` from pod name; `helm-lint` + `release-charts` workflows; `make release-check` includes helm lint/template/kubeconform.
- Design §8: k8s Host/Ingress routing without app `BASE_PATH`.
- README hero (`assets/gfire-selfhosted-hero.png`), family nav line, Related tools, TOC + **↑ Contents** links (gghstats/kzero-selfhosted pattern).
- First public GitHub publish + chart-releaser path (tag `v*` → GitHub Pages `index.yaml`).

### Changed

- Canonical host data var: **`GFIRE_STACK_HOST_DATA`** (deprecated alias **`GFIRE_HOST_DATA`** for one release).
- Minimal env: **`GFIRE_POSTGRES_*`**, **`GFIRE_REDIS_HOST_PORT`**, **`GFIRE_VALKEY_HOST_PORT`**; Postgres image **`postgres:18.4-bookworm`** (mount `/var/lib/postgresql`).
- `make release-check` validates Helm + minimal + console `compose config`.
- **Pick a path / standalone:** preferred native order documented; ROADMAP/`GSH-*` bands; DISCLAIMER; VPS pointer to gghstats `vps-recommended`.
- Default example engine pin documented as **`v1.0.2`**.

## [0.1.0] - 2026-08-07

### Added

- Initial companion scaffold (family `*-selfhosted` layout).
- **Compose minimal:** `gfire` + PostgreSQL under `run/docker-compose/minimal/`.
- Optional Compose **redis** / **valkey** profiles.
- Standalone / `docker run` path docs under `run/`.
- Design note: `docs/superpowers/specs/2026-08-07-gfire-selfhosted-design.md`.
