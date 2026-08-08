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

### Schema migrations (GSH-010)

GFire **does not** auto-migrate on startup. After Postgres is healthy:

```bash
export GFIRE_STACK_HOST_DATA=/home/gfire/gfire-data
./run/scripts/migrate-gfire-postgres.sh
```

The script loads `${GFIRE_STACK_HOST_DATA}/.env`, downloads SQL from the **gfire** GitHub tag matching **`GFIRE_VERSION`**, and runs **`migrate/migrate`** against a host-reachable DSN (`GFIRE_MIGRATE_DSN` or `127.0.0.1:${GFIRE_POSTGRES_HOST_PORT}`).

Alternative: clone gfire at the same tag and `make migrate-up`.

### Optional `gfire.yaml` mount (GSH-011)

Template: [`gfire.example.yaml`](gfire.example.yaml). Copy to `${GFIRE_STACK_HOST_DATA}/gfire.yaml`, then uncomment the volume + `--config` lines on the `gfire` service in `minimal/docker-compose.yml` (same pattern on console peers).

**Note:** `ghcr.io/hrodrig/gfire:v1.0.0` ignores nested `GFIRE_*` env on unmarshal (falls back to `storage.backend=memory`). Mount YAML **or** use a newer engine image that BindEnv-registers nested keys. Prefer env-only once that image is pinned.

### GHCR pulls

Packages `gfire`, `gfireui`, `gfireui-backend` are public on GHCR. Anonymous pull works for published multi-arch tags. Prefer **`gfireui:v0.1.1+`** (amd64+arm64); `v0.1.0` is amd64-only.

### Smoke

```bash
curl -sS "http://127.0.0.1:${GFIRE_HOST_PORT:-8080}/healthz"
```

## Console

See **[`console/README.md`](console/README.md)** — three peers, BFF, SPA, dual Postgres.

## Lab-only (not for servers)

Point **`GFIRE_STACK_HOST_DATA`** at this repo’s **`data/`** directory for a disposable local stack. Do not commit `.env`.
