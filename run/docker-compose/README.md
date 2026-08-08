# Docker Compose layouts

| Layout | Path | Purpose |
|--------|------|---------|
| **minimal** | [`minimal/`](minimal/) | GFire engine + PostgreSQL |
| **console** | _(planned)_ | Engine + gfireui-backend + SPA |

## Disclaimer

**Use at your own risk.** You are responsible for your data, secrets, and backups. See root **[DISCLAIMER.md](../../DISCLAIMER.md)**.

## Operator rule: config outside the clone

Same pattern as **gghstats-selfhosted**:

| Lives in git clone (`gfire-selfhosted`) | Lives under **`GFIRE_HOST_DATA`** (outside clone) |
|----------------------------------------|-----------------------------------------------------|
| Compose YAML, docs, scripts | **`.env`** (secrets, image pin, ports) |
| Templates (`run/common/.env.example`) | **`postgres/`** — Postgres bind-mount |
| | **`redis/`** — with `--profile redis` |
| | **`valkey/`** — with `--profile valkey` |
| | optional **`gfire.yaml`** |

`git pull` / updating this repo **must not** overwrite your settings. Never edit a live `.env` inside the clone for production.

**Own VPS:** harden SSH/firewall/updates before exposing ports. Family checklist (recommendations only): [gghstats-selfhosted `run/vps-recommended`](https://github.com/hrodrig/gghstats-selfhosted/tree/main/run/vps-recommended). Your host, your risk — [DISCLAIMER.md](../../DISCLAIMER.md).

## Minimal (recommended)

Engine sidecar: **`postgres:18.4-bookworm`** (Debian; not Alpine). Bind-mount host **`postgres/`** → container **`/var/lib/postgresql`** (official PG 18+ layout; not `/var/lib/postgresql/data`). A PG 16 data directory is **not** drop-in — dump/restore or fresh init.

```bash
export GFIRE_HOST_DATA=/home/gfire/gfire-data   # absolute, outside the clone
mkdir -p "$GFIRE_HOST_DATA/postgres"
cp run/common/.env.example "${GFIRE_HOST_DATA}/.env"
# Edit "${GFIRE_HOST_DATA}/.env":
#   - GFIRE_HOST_DATA= same absolute path
#   - POSTGRES_PASSWORD / GFIRE_STORAGE_POSTGRES_DSN
#   - GFIRE_VERSION, GFIRE_AUTH_* as needed

./run/scripts/compose-stack.sh minimal up -d
```

Upgrade image pin (restart alone is not enough):

```bash
# edit GFIRE_VERSION in ${GFIRE_HOST_DATA}/.env
./run/scripts/compose-stack.sh minimal pull
./run/scripts/compose-stack.sh minimal up -d
```

Optional Redis / ValKey profiles (data under HOST_DATA, not in the clone):

```bash
mkdir -p "${GFIRE_HOST_DATA}/redis"
# set GFIRE_STORAGE_BACKEND=redis and GFIRE_STORAGE_REDIS_ADDR=redis:6379 in .env
./run/scripts/compose-stack.sh minimal --profile redis up -d

mkdir -p "${GFIRE_HOST_DATA}/valkey"
./run/scripts/compose-stack.sh minimal --profile valkey up -d
```

Raw compose (equivalent):

```bash
docker compose --env-file "${GFIRE_HOST_DATA}/.env" -p gfire \
  -f run/docker-compose/minimal/docker-compose.yml up -d
```

### Schema migrations

GFire **does not** auto-migrate on startup. Apply PostgreSQL migrations from the **gfire** source tree (same tag as **`GFIRE_VERSION`**):

```bash
# Postgres published on POSTGRES_HOST_PORT (default 5432)
export GFIRE_STORAGE_POSTGRES_DSN='postgres://gfire:CHANGE@127.0.0.1:5432/gfire?sslmode=disable'
cd /path/to/gfire && git checkout v1.0.0 && make migrate-up
```

A first-class migrate helper in this companion is a follow-up.

### Smoke

```bash
curl -sS "http://127.0.0.1:${GFIRE_HOST_PORT:-8080}/healthz"
# → {"status":"ok"}
```

### Lab-only (not for servers)

Point **`GFIRE_HOST_DATA`** at this repo’s **`data/`** directory if you need a disposable local stack. Still use a copied `.env` under that directory — do not commit it (`.gitignore` ignores `.env`).
