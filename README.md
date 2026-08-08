# gfire-selfhosted

[![Version](https://img.shields.io/badge/version-0.1.0-blue)](./VERSION)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![App image on GHCR](https://img.shields.io/badge/image-ghcr.io%2Fhrodrig%2Fgfire-2496ED?logo=github)](https://github.com/hrodrig/gfire/pkgs/container/gfire)
[![gfire app](https://img.shields.io/badge/app-hrodrig%2Fgfire-181717?logo=github)](https://github.com/hrodrig/gfire)

Deployment manifests for **[GFire](https://github.com/hrodrig/gfire)** — Compose, `docker run`, standalone runbooks, and (planned) Helm. **This repository is the home for all deployment-related work.** **[hrodrig/gfire](https://github.com/hrodrig/gfire)** is the **application** source, binaries, and container image only.

**Console companions** (separate repos): [gfireui](https://github.com/hrodrig/gfireui) · [gfireui-backend](https://github.com/hrodrig/gfireui-backend)

**Releases:** Root **`VERSION`** and Git tags **`v<semver>`** on **`main`** name repository snapshots. Work in progress lands on **`develop`** first.

**Design:** [docs/superpowers/specs/2026-08-07-gfire-selfhosted-design.md](./docs/superpowers/specs/2026-08-07-gfire-selfhosted-design.md) · [Console stack](./docs/superpowers/specs/2026-08-07-gfire-selfhosted-console-stack-design.md) · **Roadmap:** [ROADMAP.md](./ROADMAP.md)

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
| **Compose console** (3 peers + UI + BFF) | [Docker Compose console](#docker-compose-console) |
| **Kubernetes** | [Kubernetes Helm](#kubernetes-helm) _(planned)_ |
| **Build from source** | [Last resort](run/standalone/linux/README.md#from-source-last-resort) |

**Config outside the clone (gghstats-style):** copy the stack template → **`${GFIRE_STACK_HOST_DATA}/.env`**, keep durable data under that directory, prefer **[`run/scripts/compose-stack.sh`](run/scripts/compose-stack.sh)**. Deprecated alias: **`GFIRE_HOST_DATA`** (one release). `git pull` must not flatten secrets or DB files.

| Under **`${GFIRE_STACK_HOST_DATA}/`** | When |
|--------------------------------------|------|
| **`.env`** | Always (secrets, pins, ports) |
| **`postgres/`** | Engine Postgres bind-mount |
| **`postgres-ui/`** | Console stack (BFF DB) |
| **`migrations-ui/`** | Console (extract via `extract-gfireui-migrations.sh`) |
| **`redis/`** | `--profile redis` |
| **`valkey/`** | `--profile valkey` |
| **`gfire.yaml`** | Optional (if you mount app config later) |

Default engine image tag in examples: **`v1.0.0`**. Set **`GFIRE_VERSION`** (and console `GFIREUI_*_VERSION`) in **`${GFIRE_STACK_HOST_DATA}/.env`**.

**Your own VPS:** harden the host before exposing GFire. Review family guidance at **[gghstats-selfhosted `run/vps-recommended`](https://github.com/hrodrig/gghstats-selfhosted/tree/main/run/vps-recommended)**. See also [DISCLAIMER.md](./DISCLAIMER.md).

**Packaging note:** gfire Releases today publish **archives + GHCR**. Homebrew / `.deb` / `.rpm` slots are documented; fill when upstream ships them.

---

## Standalone (native)

See **[`run/standalone/README.md`](run/standalone/README.md)** — packaged installs first; tarball / [install script](https://get.gfire.hermesrodriguez.com/install.sh); compile only if nothing else fits.

---

## Docker single container

See **[`run/docker/README.md`](run/docker/README.md)**. Distroless image: pass **`server`** as the command (default CMD is `version`).

---

## Docker Compose minimal

```bash
export GFIRE_STACK_HOST_DATA=/home/gfire/gfire-data   # outside the clone
mkdir -p "$GFIRE_STACK_HOST_DATA/postgres"
cp run/common/.env.example "${GFIRE_STACK_HOST_DATA}/.env"
# edit secrets + set GFIRE_STACK_HOST_DATA to the same absolute path

./run/scripts/compose-stack.sh minimal up -d
```

Then apply **PostgreSQL migrations** from the gfire repo (same tag as **`GFIRE_VERSION`**). Details: [`run/docker-compose/README.md`](run/docker-compose/README.md).

```bash
curl -sS http://127.0.0.1:8080/healthz
```

---

## Docker Compose console

Happy path for **UI + three gfire peers**: see **[`run/docker-compose/console/README.md`](run/docker-compose/console/README.md)**.

```bash
export GFIRE_STACK_HOST_DATA=/home/gfire/gfire-stack-data
mkdir -p "$GFIRE_STACK_HOST_DATA"/{postgres,postgres-ui}
cp run/docker-compose/console/.env.example "${GFIRE_STACK_HOST_DATA}/.env"
# edit secrets + pins; extract BFF migrations; apply engine migrations
./run/scripts/compose-stack.sh console up -d
```

Requires published (or locally overridden) **gfireui** / **gfireui-backend** images.

---

## Kubernetes Helm

**Planned.** Chart will live at `run/kubernetes/helm/gfire/`. See the [design doc](./docs/superpowers/specs/2026-08-07-gfire-selfhosted-design.md).

---

## Repository layout

```text
run/
  common/.env.example              # minimal template → GFIRE_STACK_HOST_DATA/.env
  scripts/compose-stack.sh         # stacks: minimal | console
  scripts/extract-gfireui-migrations.sh
  docker-compose/minimal/
  docker-compose/console/          # 3 peers + BFF + SPA
  standalone/
  kubernetes/                        # helm planned
docs/superpowers/specs/
# NOT in git: ${GFIRE_STACK_HOST_DATA}/.env, postgres*/, secrets
```

---

## Versioning

| Field | Meaning |
|-------|---------|
| Root **`VERSION`** | This infra repo (tags `v…` on `main`) |
| **`GFIRE_VERSION`** / image tag | Upstream **gfire** on GHCR |
| **`GFIREUI_*_VERSION`** | Console image pins |
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
