# `run/` — operator paths

| Path | Purpose |
|------|---------|
| [`common/.env.example`](common/.env.example) | Minimal template — copy to **`${GFIRE_STACK_HOST_DATA}/.env`** |
| [`scripts/compose-stack.sh`](scripts/compose-stack.sh) | Compose wrapper; stacks **`minimal`** \| **`console`** |
| [`scripts/extract-gfireui-migrations.sh`](scripts/extract-gfireui-migrations.sh) | Copy BFF migrations from backend image → **`migrations-ui/`** |
| [`docker/`](docker/) | Single-container `docker run` |
| [`docker-compose/`](docker-compose/) | Compose layouts (minimal + console) |
| [`standalone/`](standalone/) | Native: brew → deb/rpm → install.sh/tarball → **source last** |
| [`kubernetes/`](kubernetes/) | Helm chart (planned); manifests placeholder |

**`GFIRE_STACK_HOST_DATA`:** live `.env` + durable dirs **`postgres/`** (and console **`postgres-ui/`**, **`migrations-ui/`**), plus **`redis/`** / **`valkey/`** when profiles are used — all **outside** this clone. Deprecated alias: **`GFIRE_HOST_DATA`**.

**Own VPS security:** [gghstats-selfhosted `run/vps-recommended`](https://github.com/hrodrig/gghstats-selfhosted/tree/main/run/vps-recommended) + root [DISCLAIMER.md](../DISCLAIMER.md).

**PostgreSQL schema:** the engine does not auto-migrate — see [docker-compose/README.md](docker-compose/README.md#schema-migrations).
