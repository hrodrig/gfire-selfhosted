# GFire Selfhosted Design

**Date:** 2026-08-07  
**Status:** Approved  
**Repo:** [hrodrig/gfire-selfhosted](https://github.com/hrodrig/gfire-selfhosted)  
**Local:** `/Volumes/Data/addlink/github/gfire-selfhosted`

## 1. Goal

Ship a **companion ops repository** that consolidates installation paths for the GFire ecosystem (standalone, Docker, Compose, Kubernetes/Helm) without embedding application source.

GFire stays **headless**. Console pieces (`gfireui`, `gfireui-backend`) remain separate product repos; this repo pins their images when a console Compose/Helm profile exists.

## 2. Non-goals

- Monorepo of Go/Svelte source
- License keys / commercial store / my.gfire.net
- Embedding UI into the `gfire` binary
- Traefik / observability stacks on day one (gghstats-style extras later)

## 3. Family pattern

Align with sibling `*-selfhosted` repos (`pgwd-selfhosted`, `gghstats-selfhosted`, multi-app `kui-selfhosted`):

| Rule | Detail |
|------|--------|
| Layout | Everything operator-facing under **`run/`** |
| Version triad | Root **`VERSION`** (this repo) ≠ Helm **`Chart.yaml` `version`** ≠ **`GFIRE_VERSION`** (app image) |
| Secrets + durable data | **`${GFIRE_STACK_HOST_DATA}/`** outside the clone (`.env`, `postgres/`, …); never live secrets in git. Deprecated alias: `GFIRE_HOST_DATA` (one release). |
| Compose wrapper | **`run/scripts/compose-stack.sh`** always uses **`${GFIRE_STACK_HOST_DATA}/.env`** |
| Env prefixes | `GFIRE_STACK_*` (stack) · `GFIRE_*` (engine) · `GFIREUI_*` (SPA) · `GFIREUI_BACKEND_*` (BFF) · `PUBLIC_GFIREUI_*` (browser) — see [console stack design](./2026-08-07-gfire-selfhosted-console-stack-design.md) |
| Images | Pull **`ghcr.io/hrodrig/<app>:<tag>`** — no vendored binaries |
| Gitignore | Deny-all + whitelist; ignore `.env` and in-repo lab data dirs |
| Validation | **`make release-check`** (Compose `config` now; Helm lint later) |

Base model: **pgwd / gghstats**. Console: multi-pin `*_VERSION` under one `GFIRE_STACK_HOST_DATA` ([console stack design](./2026-08-07-gfire-selfhosted-console-stack-design.md)).

## 4. Product ownership

| Repo | Owns |
|------|------|
| gfire | Engine, Releases, GHCR `ghcr.io/hrodrig/gfire` |
| gfireui-backend | BFF |
| gfireui | SPA |
| **gfire-selfhosted** | Compose, Helm, runbooks, pins |

## 5. Install paths (Pick a path)

**Native preference (document even before all artifacts exist):**

1. Homebrew  
2. `.deb` / `.rpm` (+ systemd on Linux)  
3. install script / release tarball-zip  
4. `docker run` / Compose / Helm  
5. **Build from source — last resort**

| Path | Location | Phase |
|------|----------|-------|
| Homebrew / deb / rpm / tarball / install.sh | `run/standalone/` → upstream Releases (+ get host) | 1 |
| `docker run` | `run/docker/` | 1 |
| Compose minimal | `run/docker-compose/minimal/` (gfire + Postgres) | 1 |
| Helm | `run/kubernetes/helm/gfire/` | 2 |
| Compose console | `run/docker-compose/console/` | 3 |
| From source | Documented last under `run/standalone/*/README.md` | 1 |

**Honesty:** as of gfire v1.0.0, GoReleaser ships archives + GHCR (no nfpm/Homebrew in `.goreleaser.yaml` yet). Selfhosted keeps the preferred order; fill package examples when product publishes assets.

## 6. Compose minimal contract

- Image: `ghcr.io/hrodrig/gfire:${GFIRE_VERSION}` (default **`v1.0.0`**), override via **`GFIRE_IMAGE`**.
- Command: **`server`** (distroless default CMD is `version`).
- Storage default: **postgres** with DSN to compose service **`postgres`** (`postgres:18.4-bookworm`; bind host `postgres/` → `/var/lib/postgresql`).
- Optional profiles: **`redis`**, **`valkey`** (sidecars; backend switch via env).
- Auth: optional Bearer via **`GFIRE_AUTH_*`**.
- **Migrations:** not automatic; operator applies gfire Postgres migrations (same tag as image). Follow-up: first-class migrate helper in this repo.

## 7. Bands / backlog

Tracked in root **[ROADMAP.md](../../../ROADMAP.md)** (`GSH-*` IDs) and [../plans/2026-08-07-gfire-selfhosted-bands.md](../plans/2026-08-07-gfire-selfhosted-bands.md).

| Band | Theme |
|------|--------|
| 0 | Scaffold MVP |
| 1 | Operator polish (migrate helper, smoke, cross-links) |
| 2 | Helm chart + CI |
| 3 | Console Compose/Helm (blocked on gfireui* images) |
| 4 | Native packaging sync (brew/deb/rpm when upstream ships) |
| 5 | kind / platforms / optional Traefik·obs |

## 8. Kubernetes exposure (routing)

**Decision (2026-08-08):** end-state is everything runnable on Kubernetes. Edge routing follows **gghstats** — not app-level `BASE_PATH`.

| Rule | Detail |
|------|--------|
| App roots | Stay fixed: gfire `/v1` + `/healthz`, BFF `/api` + `/healthz`, SPA `/` |
| Public edge | Prefer **Host**-based Ingress (console host, API host). Engine default = **ClusterIP** (not public) |
| Same-host split | Optional: PathPrefix + **rewrite at Ingress** (`/api` → BFF, `/` → SPA). Rewrite so pods still see root paths |
| Collision fear | Identical paths on one Host without differentiation → Ingress problem, not a reason to add `BASE_PATH` to all binaries |
| Out of scope | Configurable mount prefix inside gfire / gfireui / gfireui-backend |

Helm Band 2 (`GSH-020+`) implements this contract.

## 9. Docs location

Design, plans, and ROADMAP live **in this public repo**. Strategy notes (`PLAN-oss-adoption`, commercial) stay in the private Hermès core — not here.
