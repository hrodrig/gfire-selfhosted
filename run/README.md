# `run/` — operator paths

| Path | Purpose |
|------|---------|
| [`common/.env.example`](common/.env.example) | Template only — copy to **`${GFIRE_HOST_DATA}/.env`** |
| [`scripts/compose-stack.sh`](scripts/compose-stack.sh) | Compose wrapper; requires **`GFIRE_HOST_DATA`** |
| [`docker/`](docker/) | Single-container `docker run` |
| [`docker-compose/`](docker-compose/) | Compose layouts (minimal now; console later) |
| [`standalone/`](standalone/) | Native: brew → deb/rpm → install.sh/tarball → **source last** |
| [`kubernetes/`](kubernetes/) | Helm chart (planned); manifests placeholder |

**`GFIRE_HOST_DATA`:** live `.env` + durable dirs **`postgres/`**, and when profiles are used **`redis/`** / **`valkey/`**, all **outside** this clone so `git pull` never overwrites settings (gghstats pattern).

**Own VPS security:** [gghstats-selfhosted `run/vps-recommended`](https://github.com/hrodrig/gghstats-selfhosted/tree/main/run/vps-recommended) + root [DISCLAIMER.md](../DISCLAIMER.md).

**PostgreSQL schema:** the engine does not auto-migrate — see [docker-compose/README.md](docker-compose/README.md#schema-migrations).
