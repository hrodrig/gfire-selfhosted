# Docker Compose layouts

| Layout | Path | Purpose |
|--------|------|---------|
| **minimal** | [`minimal/`](minimal/) | One GFire engine + PostgreSQL |
| **console** | [`console/`](console/) | Three gfire peers + gfireui-backend + SPA |

## Disclaimer

**Use at your own risk.** You are responsible for your data, secrets, and backups. See root **[DISCLAIMER.md](../../DISCLAIMER.md)**.

## Operator rule: config outside the clone

Same pattern as **gghstats-selfhosted**:

| Lives in git clone (`gfire-selfhosted`) | Lives under **`GFIRE_STACK_HOST_DATA`** (outside clone) |
|----------------------------------------|---------------------------------------------------------|
| Compose YAML, docs, scripts | **`.env`** (secrets, image pin, ports) |
| Templates (`.env.example`) | **`postgres/`** — engine Postgres bind-mount |
| | **`postgres-ui/`** — console BFF DB |
| | **`migrations-ui/`** — extracted BFF SQL |
| | **`redis/`** / **`valkey/`** — optional profiles |
| | optional **`gfire.yaml`** |

Deprecated alias: **`GFIRE_HOST_DATA`** (one release; wrapper warns).

`git pull` / updating this repo **must not** overwrite your settings.

**Own VPS:** harden SSH/firewall/updates before exposing ports. Family checklist: [gghstats-selfhosted `run/vps-recommended`](https://github.com/hrodrig/gghstats-selfhosted/tree/main/run/vps-recommended). [DISCLAIMER.md](../../DISCLAIMER.md).

## Minimal

Engine sidecar: **`postgres:18.4-bookworm`**. Bind-mount host **`postgres/`** → **`/var/lib/postgresql`**. A PG 16 data directory is **not** drop-in.

```bash
export GFIRE_STACK_HOST_DATA=/home/gfire/gfire-data
mkdir -p "$GFIRE_STACK_HOST_DATA/postgres"
cp run/common/.env.example "${GFIRE_STACK_HOST_DATA}/.env"
# Edit: GFIRE_STACK_HOST_DATA, GFIRE_POSTGRES_PASSWORD, DSN, GFIRE_VERSION

./run/scripts/compose-stack.sh minimal up -d
```

Upgrade pin: edit `GFIRE_VERSION`, then `pull` + `up -d` (not `restart` alone).

Optional Redis / ValKey (commented knobs in `.env.example`):

```bash
mkdir -p "${GFIRE_STACK_HOST_DATA}/redis"
./run/scripts/compose-stack.sh minimal --profile redis up -d
```

### Schema migrations

GFire **does not** auto-migrate on startup. Apply PostgreSQL migrations from the **gfire** source tree (same tag as **`GFIRE_VERSION`**):

```bash
export GFIRE_STORAGE_POSTGRES_DSN='postgres://gfire:CHANGE@127.0.0.1:5432/gfire?sslmode=disable'
cd /path/to/gfire && git checkout v1.0.0 && make migrate-up
```

### Smoke

```bash
curl -sS "http://127.0.0.1:${GFIRE_HOST_PORT:-8080}/healthz"
```

## Console

See **[`console/README.md`](console/README.md)** — three peers, BFF, SPA, dual Postgres.

## Lab-only (not for servers)

Point **`GFIRE_STACK_HOST_DATA`** at this repo’s **`data/`** directory for a disposable local stack. Do not commit `.env`.
