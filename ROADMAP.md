# gfire-selfhosted Roadmap

Deployment companion for [gfire](https://github.com/hrodrig/gfire) (+ future console pins).  
Design: [docs/superpowers/specs/2026-08-07-gfire-selfhosted-design.md](./docs/superpowers/specs/2026-08-07-gfire-selfhosted-design.md)

**Status key:** ✅ done · ⬜ pending · 🔒 blocked on upstream product

---

## Current focus

Band **0** scaffold in working tree (pre-first-commit). Next: migrate helper + Helm (Bands 1–2).

---

## Band 0 — Scaffold (MVP)

| ID | Item | Status |
|----|------|--------|
| GSH-001 | Family layout: whitelist `.gitignore`, community files, `VERSION` `0.1.0` | ✅ |
| GSH-002 | Design doc under `docs/superpowers/specs/` | ✅ |
| GSH-003 | Pick a path README (native order + containers; source last) | ✅ |
| GSH-004 | Compose minimal: gfire + Postgres; redis/valkey profiles | ✅ |
| GSH-005 | `GFIRE_HOST_DATA` outside clone + `run/scripts/compose-stack.sh` | ✅ |
| GSH-006 | Standalone / docker run docs (linux, macos, windows) | ✅ |
| GSH-007 | `make release-check` (Compose `config`) | ✅ |
| GSH-008 | First commit + GitHub remote publish | ⬜ |

---

## Band 1 — Operator polish

| ID | Item | Status |
|----|------|--------|
| GSH-010 | First-class **migrate** helper (script/one-shot) for Postgres schema at pinned `GFIRE_VERSION` | ⬜ |
| GSH-011 | Optional mount path for `${GFIRE_HOST_DATA}/gfire.yaml` documented + compose snippet ready | ⬜ |
| GSH-015 | Document HOST_DATA layout for `postgres/` + `redis/` + `valkey/`; VPS hardening link → gghstats `vps-recommended` | ✅ |
| GSH-012 | Smoke recipe: healthz + echo enqueue (Makefile or script) | ⬜ |
| GSH-013 | Cross-links: Related tools in gfire / gfireui READMEs → this repo | ⬜ |
| GSH-014 | Sync PLAN-oss private signal “Companion ops exists” (Hermès; not in this repo) | ⬜ |

---

## Band 2 — Kubernetes Helm

| ID | Item | Status |
|----|------|--------|
| GSH-020 | Chart `run/kubernetes/helm/gfire/` (Deployment/Service/Config/Secret) | ⬜ |
| GSH-021 | External Postgres by default; optional DB dependency later | ⬜ |
| GSH-022 | `make release-check` → helm lint + template + kubeconform | ⬜ |
| GSH-023 | CI workflow helm-lint (family pattern) | ⬜ |
| GSH-024 | Chart releaser / GitHub Pages repo (when ready) | ⬜ |

---

## Band 3 — Console stack

| ID | Item | Status | Notes |
|----|------|--------|-------|
| GSH-030 | `run/docker-compose/console/` multi-pin (`STACK_HOST_DATA` / kui-style) | ⬜ | Needs runnable gfireui + backend images |
| GSH-031 | Bootstrap admin env documented (`GFIREUI_BACKEND_BOOTSTRAP_*`) | ⬜ | Platform design locked |
| GSH-032 | Helm values / subchart overlay for console | ⬜ | After GSH-020 |

🔒 Blocked until gfireui* publish GHCR/release tags suitable for ops.

---

## Band 4 — Native packaging sync

Fill real install examples when **gfire** product ships artifacts (this repo does not build packages).

| ID | Item | Status |
|----|------|--------|
| GSH-040 | Homebrew formula path verified + macos standalone docs updated | 🔒 / ⬜ |
| GSH-041 | `.deb` + systemd examples (asset names from Releases) | 🔒 / ⬜ |
| GSH-042 | `.rpm` + systemd examples | 🔒 / ⬜ |
| GSH-043 | Align install.sh / get-host docs with current get.gfire.* host | ⬜ |

---

## Band 5 — Hardening / CI labs

| ID | Item | Status |
|----|------|--------|
| GSH-050 | kind e2e for Helm chart | ⬜ |
| GSH-051 | Optional Ansible compose platform tests (pgwd/gghstats style) | ⬜ |
| GSH-052 | Traefik / edge stack (gghstats-style extras) — only if dogfood needs it | ⬜ |
| GSH-053 | Observability sidecar stack — only if dogfood needs it | ⬜ |

---

## Out of scope (companion)

- Application Go/Svelte source (lives in product repos)
- `gfire-store` / my.gfire.net / commercial control plane
- Embedding UI into the gfire binary
- Raw hand-maintained k8s YAML as the primary path (Helm first)
- Operating or guaranteeing end-user data (see [DISCLAIMER.md](./DISCLAIMER.md))

---

## Shipped

| Band | Highlights | Repo VERSION |
|------|------------|--------------|
| — | _(none tagged yet)_ | — |

Update this table when tagging `v*` on `main`.
