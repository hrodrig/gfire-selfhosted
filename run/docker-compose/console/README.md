# Compose — console stack

**Use at your own risk.** You are responsible for your data, secrets, and backups. See root **[DISCLAIMER.md](../../../DISCLAIMER.md)**.

Credible proof layout: **three gfire peer nodes** (`gfire-1`…`gfire-3`) + **gfireui-backend** + **gfireui** SPA + dual Postgres (`postgres:18.4-bookworm`).

Design: [console-stack design](../../../docs/superpowers/specs/2026-08-07-gfire-selfhosted-console-stack-design.md).

## Prerequisites

- Docker Compose v2
- Images (GHCR or local overrides via `*_IMAGE`):
  - `ghcr.io/hrodrig/gfire:${GFIRE_VERSION}`
  - `ghcr.io/hrodrig/gfireui-backend:${GFIREUI_BACKEND_VERSION}`
  - `ghcr.io/hrodrig/gfireui:${GFIREUI_VERSION}` (static SPA; listen port **80** in compose — adjust if your image differs)
- Engine Postgres migrations applied (same tag as `GFIRE_VERSION`; not auto on `gfire server`)

## Bring up

```bash
export GFIRE_STACK_HOST_DATA=/home/gfire/gfire-stack-data   # outside the clone
mkdir -p "$GFIRE_STACK_HOST_DATA"/{postgres,postgres-ui}
cp run/docker-compose/console/.env.example "${GFIRE_STACK_HOST_DATA}/.env"
# edit secrets, pins, GFIRE_STACK_HOST_DATA=

set -a && source "${GFIRE_STACK_HOST_DATA}/.env" && set +a
./run/scripts/extract-gfireui-migrations.sh

# Apply gfire engine migrations to GFIRE_POSTGRES_* (see minimal compose README)

./run/scripts/compose-stack.sh console up -d
```

Upgrade image pins: edit `*_VERSION` in `.env`, then `compose-stack.sh console pull` and `up -d` (not `restart` alone).

## Smoke

1. `curl -sf "http://127.0.0.1:${GFIRE_HOST_PORT:-8080}/healthz"`
2. `docker compose … ps` — `gfire-1`, `gfire-2`, `gfire-3` running
3. Three distinct `server_id` heartbeats (API/servers listing)
4. BFF on `${GFIREUI_BACKEND_HOST_PORT:-8090}` healthy
5. Browser → SPA `${GFIREUI_HOST_PORT:-8088}` — bootstrap admin login
6. Ops/summary reaches upstream gfire (not empty `gfire.base_url`)

## Notes

- BFF → `http://gfire-1:8080` (API entry). Workers run on all three peers.
- Peers 2–3 are compose-network only by default (no host ports).
- Redis/ValKey: optional `--profile redis|valkey` (engine storage only).
- Observability / Traefik: out of scope for this layout.
