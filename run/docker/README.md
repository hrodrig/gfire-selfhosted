# Docker single container

**Goal:** one GFire container, no Compose file. You supply PostgreSQL (or use `memory` backend for throwaway lab).

```bash
# Lab only — in-memory storage (no durability)
docker run -d --name gfire \
  -p 8080:8080 \
  -e GFIRE_SERVER_HOST=0.0.0.0 \
  -e GFIRE_SERVER_PORT=8080 \
  -e GFIRE_STORAGE_BACKEND=memory \
  ghcr.io/hrodrig/gfire:v1.0.0 \
  server
```

Postgres (replace DSN host with a reachable database):

```bash
docker run -d --name gfire \
  -p 8080:8080 \
  -e GFIRE_SERVER_HOST=0.0.0.0 \
  -e GFIRE_SERVER_PORT=8080 \
  -e GFIRE_STORAGE_BACKEND=postgres \
  -e GFIRE_STORAGE_POSTGRES_DSN='postgres://gfire:gfire@db-host:5432/gfire?sslmode=disable' \
  ghcr.io/hrodrig/gfire:v1.0.0 \
  server
```

Image tags: [gfire packages](https://github.com/hrodrig/gfire/pkgs/container/gfire) / [releases](https://github.com/hrodrig/gfire/releases). Match **`GFIRE_VERSION`** in [`../common/.env.example`](../common/.env.example).

**Check:** `curl -sS http://127.0.0.1:8080/healthz`

**Remove:** `docker stop gfire && docker rm gfire`

For Postgres + GFire together, prefer [Compose minimal](../docker-compose/minimal/).
