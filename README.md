<a id="readme-top"></a>

# gfire-selfhosted

[![Version](https://img.shields.io/badge/version-0.1.0-blue)](./VERSION)
[![Release](https://img.shields.io/github/v/release/hrodrig/gfire-selfhosted?label=release)](https://github.com/hrodrig/gfire-selfhosted/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![App image on GHCR](https://img.shields.io/badge/image-ghcr.io%2Fhrodrig%2Fgfire-2496ED?logo=github)](https://github.com/hrodrig/gfire/pkgs/container/gfire)
[![gfire app](https://img.shields.io/badge/app-hrodrig%2Fgfire-181717?logo=github)](https://github.com/hrodrig/gfire)
[![gghstats clones](https://gghstats.hermesrodriguez.com/api/v1/badge/hrodrig/gfire-selfhosted?metric=clones)](https://gghstats.hermesrodriguez.com/hrodrig/gfire-selfhosted)

**Repo:** [github.com/hrodrig/gfire-selfhosted](https://github.com/hrodrig/gfire-selfhosted) · **Releases:** [GitHub Releases](https://github.com/hrodrig/gfire-selfhosted/releases) · **Apps:** [gfire](https://github.com/hrodrig/gfire) · [gfireui](https://github.com/hrodrig/gfireui) · [gfireui-backend](https://github.com/hrodrig/gfireui-backend) · **Changelog:** [CHANGELOG.md](./CHANGELOG.md) · **Roadmap:** [ROADMAP.md](./ROADMAP.md) · **Disclaimer:** [DISCLAIMER.md](./DISCLAIMER.md)

![gfire-selfhosted — Compose, Helm, run/](assets/gfire-selfhosted-hero.png)

Deployment manifests for **[GFire](https://github.com/hrodrig/gfire)** — Compose, `docker run`, standalone runbooks, and **Helm**. **This repository owns deployment and infra** (charts, Compose, runbooks). Application source, binaries, and GHCR images live in the product repos:

| Product | Repo | Role |
|---------|------|------|
| Engine | [gfire](https://github.com/hrodrig/gfire) | Headless job service |
| Ops console SPA | [gfireui](https://github.com/hrodrig/gfireui) | Browser UI |
| Ops console BFF | [gfireui-backend](https://github.com/hrodrig/gfireui-backend) | Auth, RBAC, proxy |

**Releases:** Root **`VERSION`** and Git tags **`v<semver>`** on **`main`** name repository snapshots. Work in progress lands on **`develop`** first — prefer **`main`** or a **tag** for reproducible paths.

**Design:** [selfhosted design](./docs/superpowers/specs/2026-08-07-gfire-selfhosted-design.md) · [Console stack](./docs/superpowers/specs/2026-08-07-gfire-selfhosted-console-stack-design.md)

> **USE AT YOUR OWN RISK.** This is not a managed service. **You** are responsible for your data, secrets, backups, and how you run these stacks. The maintainers are **not** liable for data loss, misuse, or unsuitable deployments. Full text: **[DISCLAIMER.md](./DISCLAIMER.md)**.

**Related tools (same maintainer):**
- **[pgwd](https://github.com/hrodrig/pgwd)** — PostgreSQL connection watchdog ([live traffic](https://gghstats.hermesrodriguez.com/hrodrig/pgwd); deploy: [pgwd-selfhosted](https://github.com/hrodrig/pgwd-selfhosted))
- **[gghstats](https://github.com/hrodrig/gghstats)** — GitHub repo traffic beyond 14 days ([live demo](https://gghstats.hermesrodriguez.com); deploy: [gghstats-selfhosted](https://github.com/hrodrig/gghstats-selfhosted))
- **[kzero](https://github.com/hrodrig/kzero)** — bastion-first declarative workload reset ([live traffic](https://gghstats.hermesrodriguez.com/hrodrig/kzero); deploy: [kzero-selfhosted](https://github.com/hrodrig/kzero-selfhosted))
- **[groot](https://github.com/hrodrig/groot)** — Kubernetes diagnostics archive ([live traffic](https://gghstats.hermesrodriguez.com/hrodrig/groot); deploy: [groot-selfhosted](https://github.com/hrodrig/groot-selfhosted))

---

## Table of contents

- [Pick a path](#pick-a-path)
- [Standalone (native)](#standalone-native)
- [Docker single container](#docker-single-container)
- [Docker Compose minimal](#docker-compose-minimal)
- [Docker Compose console](#docker-compose-console)
- [Kubernetes Helm](#kubernetes-helm)
- [Repository layout](#repository-layout)
- [Versioning](#versioning)
- [Community and policies](#community-and-policies)
- [License](#license)

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
| **Kubernetes** | [Kubernetes Helm](#kubernetes-helm) |
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

Default engine image tag in examples: **`v1.0.2`**. Set **`GFIRE_VERSION`** (and console `GFIREUI_*_VERSION`) in **`${GFIRE_STACK_HOST_DATA}/.env`**.

**Your own VPS:** harden the host before exposing GFire. Review family guidance at **[gghstats-selfhosted `run/vps-recommended`](https://github.com/hrodrig/gghstats-selfhosted/tree/main/run/vps-recommended)**. See also [DISCLAIMER.md](./DISCLAIMER.md).

**Packaging note:** gfire Releases today publish **archives + GHCR**. Homebrew / `.deb` / `.rpm` slots are documented; fill when upstream ships them.

**[↑ Contents](#table-of-contents)**

---

## Standalone (native)

See **[`run/standalone/README.md`](run/standalone/README.md)** — packaged installs first; tarball / [install script](https://get.gfire.hermesrodriguez.com/install.sh); compile only if nothing else fits.

**[↑ Contents](#table-of-contents)**

---

## Docker single container

See **[`run/docker/README.md`](run/docker/README.md)**. Distroless image: pass **`server`** as the command (default CMD is `version`).

**[↑ Contents](#table-of-contents)**

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

**[↑ Contents](#table-of-contents)**

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

**[↑ Contents](#table-of-contents)**

---

## Kubernetes Helm

Chart: [`run/kubernetes/helm/gfire/`](./run/kubernetes/helm/gfire/) — engine peers, external Postgres DSN Secret, ClusterIP Service.

```bash
kubectl create secret generic gfire-postgres \
  --from-literal=dsn='postgres://gfire:gfire@postgres:5432/gfire?sslmode=disable'

helm upgrade --install gfire ./run/kubernetes/helm/gfire \
  --set postgres.existingSecret=gfire-postgres \
  --set image.tag=v1.0.2
```

Edge routing: Host-based Ingress (or PathPrefix + rewrite). Apps keep root paths — no `BASE_PATH` (design §8). Chart index publishes to GitHub Pages via chart-releaser on tags `v*`.

Console Helm overlay: later (`GSH-032`).

**[↑ Contents](#table-of-contents)**

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
  kubernetes/helm/gfire/             # engine chart
  kubernetes/manifests/               # prefer helm template
docs/superpowers/specs/
assets/gfire-selfhosted-hero.png
# NOT in git: ${GFIRE_STACK_HOST_DATA}/.env, postgres*/, secrets
```

**[↑ Contents](#table-of-contents)**

---

## Versioning

| Field | Meaning |
|-------|---------|
| Root **`VERSION`** | This infra repo (tags `v…` on `main`) |
| **`GFIRE_VERSION`** / image tag | Upstream **gfire** on GHCR |
| **`GFIREUI_*_VERSION`** | Console image pins |
| Helm **`Chart.yaml` `version:`** | Chart package (`0.1.0` today) |

**[↑ Contents](#table-of-contents)**

---

## Community and policies

**Policies:** [Community and policies](#community-and-policies), [community standards](#community-standards) — changelog, contributing, security, code of conduct, agent guidelines.

- [DISCLAIMER](./DISCLAIMER.md) — use at your own risk; your data, your responsibility
- [ROADMAP](./ROADMAP.md)
- [CHANGELOG](./CHANGELOG.md)
- [CONTRIBUTING](./CONTRIBUTING.md)
- [SECURITY](./SECURITY.md)
- [CODE_OF_CONDUCT](./CODE_OF_CONDUCT.md)
- [AGENTS](./AGENTS.md)

### Community standards

See [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md) and [CONTRIBUTING.md](./CONTRIBUTING.md).

**[↑ Contents](#table-of-contents)** · **[↑ Top](#readme-top)**

---

## License

[MIT](./LICENSE) — see also [DISCLAIMER.md](./DISCLAIMER.md).

**[↑ Contents](#table-of-contents)** · **[↑ Top](#readme-top)**
