# gfire-selfhosted

[![Version](https://img.shields.io/badge/version-0.1.0-blue)](./VERSION)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![App image on GHCR](https://img.shields.io/badge/image-ghcr.io%2Fhrodrig%2Fgfire-2496ED?logo=github)](https://github.com/hrodrig/gfire/pkgs/container/gfire)
[![gfire app](https://img.shields.io/badge/app-hrodrig%2Fgfire-181717?logo=github)](https://github.com/hrodrig/gfire)

Deployment manifests for **[GFire](https://github.com/hrodrig/gfire)** — Compose, `docker run`, standalone runbooks, and (planned) Helm. **This repository is the home for all deployment-related work.** **[hrodrig/gfire](https://github.com/hrodrig/gfire)** is the **application** source, binaries, and container image only.

**Console companions** (separate repos): [gfireui](https://github.com/hrodrig/gfireui) · [gfireui-backend](https://github.com/hrodrig/gfireui-backend)

**Releases:** Root **`VERSION`** and Git tags **`v<semver>`** on **`main`** name repository snapshots. Work in progress lands on **`develop`** first.

**Design:** [docs/superpowers/specs/2026-08-07-gfire-selfhosted-design.md](./docs/superpowers/specs/2026-08-07-gfire-selfhosted-design.md) · **Roadmap:** [ROADMAP.md](./ROADMAP.md)

> **USE AT YOUR OWN RISK.** This is not a managed service. **You** are responsible for your data, secrets, backups, and how you run these stacks. The maintainers are **not** liable for data loss, misuse, or unsuitable deployments. Full text: **[DISCLAIMER.md](./DISCLAIMER.md)**.

---

## Pick a path

**Native install preference:** Homebrew → `.deb`/`.rpm` → install script / tarball → containers → **build from source last**.

| You want… | Section |
|-----------|---------|
| **Homebrew** | [Standalone](run/standalone/macos/README.md) (when formula published) |
| **Linux `.deb` / `.rpm` + systemd** | [run/standalone/linux/README.md](run/standalone/linux/README.md) |
| **install.sh / release archive** | [Standalone](#standalone-native) |
| **Single container** (`docker run`) | [Docker single container](#docker-single-container) |
| **Compose** (engine + Postgres) | [Docker Compose minimal](#docker-compose-minimal) |
| **Kubernetes** | [Kubernetes Helm](#kubernetes-helm) _(planned)_ |
| **Build from source** | [Last resort](run/standalone/linux/README.md#from-source-last-resort) |

**Config outside the clone (gghstats-style):** copy **[`run/common/.env.example`](run/common/.env.example)** → **`${GFIRE_HOST_DATA}/.env`**, keep durable data under that same host directory, and always pass that env file (prefer **[`run/scripts/compose-stack.sh`](run/scripts/compose-stack.sh)**). `git pull` on this repo must not flatten secrets or DB files.

| Under **`${GFIRE_HOST_DATA}/`** | When |
|---------------------------------|------|
| **`.env`** | Always (secrets, pins, ports) |
| **`postgres/`** | Compose minimal (Postgres bind-mount) |
| **`redis/`** | `--profile redis` |
| **`valkey/`** | `--profile valkey` |
| **`gfire.yaml`** | Optional (if you mount app config later) |

Default image tag in examples: **`v1.0.0`** ([gfire releases](https://github.com/hrodrig/gfire/releases)). Set **`GFIRE_VERSION`** in **`${GFIRE_HOST_DATA}/.env`**.

**Your own VPS:** harden the host before exposing GFire. Review family guidance at **[gghstats-selfhosted `run/vps-recommended`](https://github.com/hrodrig/gghstats-selfhosted/tree/main/run/vps-recommended)** (SSH, firewall, updates — recommendations only; you validate and apply). See also [DISCLAIMER.md](./DISCLAIMER.md).

**Packaging note:** gfire Releases today publish **archives + GHCR**. Homebrew / `.deb` / `.rpm` are the preferred native paths once upstream ships them (same hygiene as pgwd/gghstats); this repo documents the slots now.

---

## Standalone (native)

See **[`run/standalone/README.md`](run/standalone/README.md)** — packaged installs first; tarball / [install script](https://get.gfire.hermesrodriguez.com/install.sh); compile only if nothing else fits.

---

## Docker single container

See **[`run/docker/README.md`](run/docker/README.md)**. Distroless image: pass **`server`** as the command (default CMD is `version`).

---

## Docker Compose minimal

```bash
export GFIRE_HOST_DATA=/home/gfire/gfire-data   # outside the clone
mkdir -p "$GFIRE_HOST_DATA/postgres"
# If you will use a profile: also mkdir -p "$GFIRE_HOST_DATA/redis" or .../valkey
cp run/common/.env.example "${GFIRE_HOST_DATA}/.env"
# edit secrets + set GFIRE_HOST_DATA to the same absolute path

./run/scripts/compose-stack.sh minimal up -d
# Redis backend example:
# ./run/scripts/compose-stack.sh minimal --profile redis up -d
```

Then apply **PostgreSQL migrations** from the gfire repo (same tag as **`GFIRE_VERSION`**) — the engine does not auto-migrate. Details: [`run/docker-compose/README.md`](run/docker-compose/README.md).

```bash
curl -sS http://127.0.0.1:8080/healthz
```

---

## Kubernetes Helm

**Planned.** Chart will live at `run/kubernetes/helm/gfire/`. See the [design doc](./docs/superpowers/specs/2026-08-07-gfire-selfhosted-design.md).

---

## Repository layout

```text
run/
  common/.env.example          # template only → copy to GFIRE_HOST_DATA/.env
  scripts/compose-stack.sh     # always --env-file $GFIRE_HOST_DATA/.env
  docker/
  docker-compose/minimal/
  standalone/
  kubernetes/                    # helm planned
docs/superpowers/specs/
# NOT in git: ${GFIRE_HOST_DATA}/.env, postgres/, redis/, valkey/, secrets
```

---

## Versioning

| Field | Meaning |
|-------|---------|
| Root **`VERSION`** | This infra repo (tags `v…` on `main`) |
| **`GFIRE_VERSION`** / image tag | Upstream **gfire** on GHCR |
| Helm **`Chart.yaml` `version:`** | Chart package only (when chart exists) |

---

## Community and policies

- [DISCLAIMER](./DISCLAIMER.md) — use at your own risk; your data, your responsibility
- [ROADMAP](./ROADMAP.md)
- [CHANGELOG](./CHANGELOG.md)
- [CONTRIBUTING](./CONTRIBUTING.md)
- [SECURITY](./SECURITY.md)
- [CODE_OF_CONDUCT](./CODE_OF_CONDUCT.md)
- [AGENTS](./AGENTS.md)

## License

[MIT](./LICENSE) — see also [DISCLAIMER.md](./DISCLAIMER.md).
