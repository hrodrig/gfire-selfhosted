# GFire Selfhosted — Console Compose Stack Design

**Date:** 2026-08-07  
**Status:** Draft (awaiting user review)  
**Repo:** [hrodrig/gfire-selfhosted](https://github.com/hrodrig/gfire-selfhosted)  
**Parent:** [2026-08-07-gfire-selfhosted-design.md](./2026-08-07-gfire-selfhosted-design.md)  
**Roadmap:** Band 3 (`GSH-030`, `GSH-031`, …)

## 1. Goal

Ship **`run/docker-compose/console/`**: one Compose project that runs a **working, attractive, credible** ops stack — **minimum three gfire peer nodes** + console BFF + SPA — with a single host-data directory and one operator `.env`.

A single engine container is **not** a fehaciente proof of GFire’s peer model. Console stack must show **three nodes** sharing one storage backend (API + workers on each).

Today UI + BFF can run in product-repo compose; the missing piece is those **engine peers** on the same network.

## 2. Non-goals (v1 console)

- More than three gfire nodes (default **exactly three**; scaling past 3 is later)
- Traefik / TLS / observability sidecars (optional later; not required for peer proof)
- Shared single Postgres for engine + console (two databases, two services)
- Building app source inside this repo (images only)
- Replacing product-repo local compose used for day-to-day UI/BFF development
- Changing **minimal** stack to three nodes (minimal stays **one** gfire for headless lab)

## 3. Env naming convention

Differentiate services **from the first character of the variable name**. No bare `POSTGRES_*` / `REDIS_*` / `STACK_*` in new templates.

| Prefix | Owner |
|--------|--------|
| `GFIRE_STACK_*` | Common to the whole ops stack (host data dir, shared wrapper concerns) |
| `GFIRE_*` | Engine app only (`gfire`) — including its Postgres and Redis/ValKey knobs |
| `GFIREUI_*` | SPA / UI only — including **console** Postgres (`GFIREUI_POSTGRES_*`) and SPA host port |
| `GFIREUI_BACKEND_*` | BFF only |
| `PUBLIC_GFIREUI_*` | Browser-public SPA config (SvelteKit `PUBLIC_*`; already used upstream) |

### 3.1 Host data rename

| Canonical | Deprecated (one release alias) |
|-----------|--------------------------------|
| `GFIRE_STACK_HOST_DATA` | `GFIRE_HOST_DATA` |

Apply rename to **minimal** and **console** together: `run/common/.env.example`, `compose-stack.sh`, README, AGENTS, parent design.

Wrapper resolution order:

1. `GFIRE_STACK_HOST_DATA` if set  
2. else `GFIRE_HOST_DATA` with a **stderr deprecation warning**  
3. else error + hint to copy the template

Live config path: **`${GFIRE_STACK_HOST_DATA}/.env`** (never inside the git clone on servers).

### 3.2 Durability layout

| Path under `GFIRE_STACK_HOST_DATA` | Used by |
|------------------------------------|---------|
| `.env` | All stacks |
| `postgres/` | Engine Postgres |
| `postgres-ui/` | Console Postgres (BFF) |
| `redis/` | `--profile redis` |
| `valkey/` | `--profile valkey` |

## 4. Architecture

One Compose file, project name **`gfire-console`**, one user-defined network.

**Credible proof = three peer containers**, not three worker goroutines inside one process. Each node: own `server_id`, same `GFIRE_STORAGE_*`, `command: ["server"]`.

**Out of scope for this diagram (later bands):** metrics, logs shipping, tracing, Traefik/TLS, Prometheus/Grafana.

### 4.1 Infrastructure diagram

```mermaid
flowchart TB
  subgraph Host["Operator host"]
    Browser["Browser"]
    subgraph HostData["GFIRE_STACK_HOST_DATA\n.env · postgres/ · postgres-ui/\nredis/ · valkey/ optional"]
      EnvFile[".env"]
      PgData["postgres/"]
      PgUiData["postgres-ui/"]
      RedisData["redis/ optional"]
      ValkeyData["valkey/ optional"]
    end
  end

  subgraph Compose["docker compose project: gfire-console"]
    subgraph Published["Published host ports"]
      PUI["GFIREUI_HOST_PORT\n→ ui:80/8088"]
      PBFF["GFIREUI_BACKEND_HOST_PORT\n→ backend:8090"]
      PG1["GFIRE_HOST_PORT\n→ gfire-1:8080"]
      PPG["GFIRE_POSTGRES_HOST_PORT\n→ postgres:5432 lab"]
      PPGUI["GFIREUI_POSTGRES_PORT\n→ postgres-ui:5432 lab"]
    end

    UI["ui\ngfireui static"]
    BFF["backend\ngfireui-backend"]
    Migrate["migrate\ngolang-migrate once"]
    PgUI["postgres-ui\nconsole DB"]

    G1["gfire-1\nserver_id=gfire-1"]
    G2["gfire-2\nserver_id=gfire-2"]
    G3["gfire-3\nserver_id=gfire-3"]

    Pg["postgres\nengine DB default"]
    Redis["redis\nprofile redis"]
    Valkey["valkey\nprofile valkey"]
  end

  Browser -->|PUBLIC_GFIREUI_API_BASE| PUI
  Browser --> PUI
  PUI --> UI
  UI -.->|browser calls host BFF URL| PBFF
  PBFF --> BFF

  BFF -->|GFIREUI_BACKEND_GFIRE_BASE_URL\nhttp://gfire-1:8080| G1
  BFF --> PgUI
  Migrate -->|up before backend| PgUI
  PgUI --- PgUiData

  G1 --> Pg
  G2 --> Pg
  G3 --> Pg
  G1 -.->|optional profile| Redis
  G2 -.-> Redis
  G3 -.-> Redis
  G1 -.->|optional profile| Valkey
  G2 -.-> Valkey
  G3 -.-> Valkey

  Pg --- PgData
  Redis -.-> RedisData
  Valkey -.-> ValkeyData
  EnvFile -.-> Compose

  PG1 --> G1
  PPG --> Pg
  PPGUI --> PgUI
```

**Request path (happy):** browser → `ui` → (browser) → `backend` → `gfire-1` API; **workers** on `gfire-1`/`gfire-2`/`gfire-3` dequeue from shared engine storage.

**ASCII (compact):**

```text
browser → SPA (GFIREUI_HOST_PORT)
            ↓ PUBLIC_GFIREUI_API_BASE (host-visible BFF URL)
         gfireui-backend (GFIREUI_BACKEND_HOST_PORT)
            ↓ http://gfire-1:8080  (API entry; any peer OK)
              + optional Bearer = GFIRE_AUTH_TOKEN
         gfire-1 ─┐
         gfire-2 ─┼─ peers, same storage
         gfire-3 ─┘
            ↓ GFIRE_STORAGE_*
         postgres | redis | valkey   (engine storage)

         postgres-ui ← gfireui-backend (GFIREUI_POSTGRES_*)
         migrate     ← golang-migrate before backend starts
```

| Service | Image (default) | Notes |
|---------|-----------------|-------|
| `postgres` | `postgres:18.4-bookworm` | Engine DB; bind `${GFIRE_STACK_HOST_DATA}/postgres` → `/var/lib/postgresql` (PG18+ image layout) |
| `gfire-1` … `gfire-3` | `ghcr.io/hrodrig/gfire:${GFIRE_VERSION}` | Three **named** services (not anonymous `scale`); distinct `GFIRE_SERVER_SERVER_ID` (`gfire-1`…`gfire-3`); override image via `GFIRE_IMAGE` |
| `postgres-ui` | `postgres:18.4-bookworm` | Console DB; bind `.../postgres-ui` → `/var/lib/postgresql` |
| `migrate` | `migrate/migrate` | BFF migrations; must complete before `backend` |
| `backend` | `ghcr.io/hrodrig/gfireui-backend:${GFIREUI_BACKEND_VERSION}` | Override via `GFIREUI_BACKEND_IMAGE` |
| `ui` | `ghcr.io/hrodrig/gfireui:${GFIREUI_VERSION}` | Static SPA image (assumed published before Band 3 ships); override via `GFIREUI_IMAGE` |
| `redis` / `valkey` | profile sidecars | Same as minimal; engine-only |

**Why named services (not `deploy.replicas: 3`):** stable DNS (`gfire-1`…), stable `server_id`, easier smoke (“three rows in servers”), no surprise hostname IDs.

**Host ports:** publish **node 1** as the lab API (`GFIRE_HOST_PORT` → `gfire-1:8080`). Nodes 2–3 need no host publish by default (compose-network only). Optional commented `GFIRE_HOST_PORT_2` / `_3` for debugging.

**Internal wiring (compose defaults; optional overrides in `.env` for advanced labs):**

- `GFIREUI_BACKEND_GFIRE_BASE_URL=http://gfire-1:8080` (enqueue/API via peer 1; workers run on all three)
- `GFIREUI_BACKEND_GFIRE_TOKEN` ← `${GFIRE_AUTH_TOKEN}` when auth enabled
- `GFIREUI_BACKEND_DATABASE_DSN` ← built from `GFIREUI_POSTGRES_*` toward `postgres-ui:5432`
- CORS allowed origins ← published SPA origin (`http://127.0.0.1:${GFIREUI_HOST_PORT}`, plus `localhost` twin)
- `PUBLIC_GFIREUI_API_BASE` must be a **browser-reachable** URL (host port), not the Docker DNS name
- All three nodes share identical storage + auth env; **only** `GFIRE_SERVER_SERVER_ID` differs per service

## 5. `.env` contract

### 5.1 Templates

| File | Role |
|------|------|
| `run/common/.env.example` | **Minimal** (+ shared host-data / rename notes). Magro: no UI/BFF vars. |
| `run/docker-compose/console/.env.example` | **Full console** — all prefixes above, including commented Redis/ValKey. |

Product repos keep their own `.env.example` for **dev**. Selfhosted owns **operator** templates only.

### 5.2 Required / default pins (console)

```bash
GFIRE_STACK_HOST_DATA=/home/gfire/gfire-stack-data
# Console proof: always three engine peers (compose services gfire-1..3). Not a knob to 1.
GFIRE_STACK_GFIRE_NODES=3

GFIRE_VERSION=v1.0.0
GFIRE_HOST_PORT=8080
# Optional debug publish for peers 2/3 (commented in .env.example):
# GFIRE_HOST_PORT_2=8081
# GFIRE_HOST_PORT_3=8082
GFIRE_AUTH_ENABLED=false
GFIRE_AUTH_TOKEN=
# Per-node server_id is set in compose (gfire-1 / gfire-2 / gfire-3), not in shared .env.
# Optional shared worker pool size per node:
# GFIRE_SERVER_WORKERS=4
GFIRE_POSTGRES_DB=gfire
GFIRE_POSTGRES_USER=gfire
GFIRE_POSTGRES_PASSWORD=change-me
GFIRE_POSTGRES_HOST_PORT=5432
GFIRE_STORAGE_BACKEND=postgres
GFIRE_STORAGE_POSTGRES_DSN=postgres://gfire:change-me@postgres:5432/gfire?sslmode=disable

GFIREUI_VERSION=v0.1.0
GFIREUI_HOST_PORT=8088
GFIREUI_POSTGRES_DB=gfireui
GFIREUI_POSTGRES_USERNAME=gfireui
GFIREUI_POSTGRES_PASSWORD=change-me
GFIREUI_POSTGRES_PORT=5433
PUBLIC_GFIREUI_API_BASE=http://127.0.0.1:8090

GFIREUI_BACKEND_VERSION=v0.1.0
GFIREUI_BACKEND_HOST_PORT=8090
GFIREUI_BACKEND_AUTH_JWT_SECRET=change-me
GFIREUI_BACKEND_BOOTSTRAP_ADMIN_EMAIL=admin@example.com
GFIREUI_BACKEND_BOOTSTRAP_ADMIN_PASSWORD=adminadmin
GFIREUI_BACKEND_BOOTSTRAP_ADMIN_FIRST_NAME=Admin
GFIREUI_BACKEND_BOOTSTRAP_ADMIN_LAST_NAME=User
```

Optional full image overrides: `GFIRE_IMAGE`, `GFIREUI_IMAGE`, `GFIREUI_BACKEND_IMAGE`.

### 5.3 Commented Redis / ValKey block (minimal + console)

Engine-only. Console Postgres (`GFIREUI_POSTGRES_*`) is unchanged when switching engine storage.

```bash
# --- Optional: Redis backend (compose --profile redis) ---
# mkdir -p "${GFIRE_STACK_HOST_DATA}/redis"
# GFIRE_STORAGE_BACKEND=redis
# GFIRE_STORAGE_REDIS_ADDR=redis:6379
# GFIRE_STORAGE_REDIS_PASSWORD=
# GFIRE_STORAGE_REDIS_DB=0
# GFIRE_REDIS_HOST_PORT=6379
# # If GFIRE_STORAGE_REDIS_PASSWORD is set, redis service must use --requirepass
# # (see run/docker-compose README).

# --- Optional: ValKey backend (compose --profile valkey) ---
# mkdir -p "${GFIRE_STACK_HOST_DATA}/valkey"
# GFIRE_STORAGE_BACKEND=valkey
# GFIRE_STORAGE_REDIS_ADDR=valkey:6379
# GFIRE_STORAGE_REDIS_PASSWORD=
# GFIRE_STORAGE_REDIS_DB=0
# GFIRE_VALKEY_HOST_PORT=6380
```

Profiles `redis` and `valkey` remain mutually exclusive in docs. Lab default: empty password. Production: set password + sidecar `requirepass`.

### 5.4 Minimal rename mapping

When updating `run/common/.env.example` / compose:

| Old | New |
|-----|-----|
| `GFIRE_HOST_DATA` | `GFIRE_STACK_HOST_DATA` |
| `POSTGRES_DB` / `USER` / `PASSWORD` / `HOST_PORT` | `GFIRE_POSTGRES_*` |
| `REDIS_HOST_PORT` | `GFIRE_REDIS_HOST_PORT` |
| `VALKEY_HOST_PORT` | `GFIRE_VALKEY_HOST_PORT` |

Compose interpolations and healthchecks must use the new names.

## 6. Migrations

| Database | Source | Mechanism |
|----------|--------|-----------|
| Engine Postgres | gfire SQL (same tag as `GFIRE_VERSION`) | Not auto on `gfire server`. Operator job / `run/scripts` helper (Band 1 `GSH-*` migrate work); document order before smoke. |
| Console Postgres | gfireui-backend migrations | Compose `migrate` service (`migrate/migrate`) `depends_on` healthy `postgres-ui`; `backend` waits for migrate success. |

How BFF migration files are obtained (extract from backend image vs pinned volume) is an implementation detail for the plan; must not require a sibling git checkout of gfireui-backend on the server.

## 7. Wrapper and docs

```bash
export GFIRE_STACK_HOST_DATA=/home/gfire/gfire-stack-data
cp run/docker-compose/console/.env.example "${GFIRE_STACK_HOST_DATA}/.env"
# edit secrets + pins
mkdir -p "${GFIRE_STACK_HOST_DATA}/postgres" "${GFIRE_STACK_HOST_DATA}/postgres-ui"
./run/scripts/compose-stack.sh console up -d
```

Stacks in `compose-stack.sh`: `minimal` | `console`.

README “Pick a path”: add **Compose console** as the happy path for “UI + engine working together”. Minimal remains headless/API-only.

## 8. Smoke checklist (post-up)

1. `GET http://127.0.0.1:${GFIRE_HOST_PORT}/healthz` → 200 (node 1)  
2. Compose: `gfire-1`, `gfire-2`, `gfire-3` all **running** / healthy  
3. Engine/servers listing (API or storage) shows **three** distinct `server_id`s (`gfire-1`…`gfire-3`) with fresh heartbeats  
4. BFF health endpoint → 200  
5. Browser login with bootstrap admin  
6. Ops/summary (or equivalent) succeeds against upstream gfire — not “empty `gfire.base_url`”  
7. (Strong) Enqueue work; observe processing attributed across more than one `server_id` when load allows

## 9. Product prerequisites (before publishing Band 3)

1. GHCR image + tag for **gfire** (exists)  
2. GHCR image + tag for **gfireui-backend**  
3. GHCR **static** image + tag for **gfireui** (assumed; adjust product repos before shipping this band)  
4. Env rename applied to minimal so console and minimal share one convention  

## 10. Relation to ROADMAP

| ID | Impact |
|----|--------|
| `GSH-030` | Implement `run/docker-compose/console/` + multi-pin `.env` |
| `GSH-031` | Bootstrap admin env documented (this design §5.2) |
| Minimal docs / script | Rename to `GFIRE_STACK_*` + `GFIRE_POSTGRES_*` (prerequisite or same delivery) |

## 11. Decisions log

| Decision | Choice |
|----------|--------|
| Happy path | Single **console** Compose (engine + BFF + SPA) |
| Engine topology (console) | **Exactly three peer nodes** (`gfire-1`…`gfire-3`); named services; shared storage |
| Minimal topology | Still **one** gfire (headless lab) |
| BFF upstream | `http://gfire-1:8080` (API entry); workers on all peers |
| Env templates | Per Compose layout — not one mega-env, not N per-service ops envs |
| Prefixes | `GFIRE_STACK_` / `GFIRE_` / `GFIREUI_` / `GFIREUI_BACKEND_` / `PUBLIC_GFIREUI_` |
| Host data | Rename to `GFIRE_STACK_HOST_DATA`; alias `GFIRE_HOST_DATA` one release |
| SPA image | Assumed published before Band 3 ships |
| Redis/ValKey | Commented blocks in both `.env.example` files; engine-only |
| Postgres image | `postgres:18.4-bookworm` for engine + console DBs; mount `/var/lib/postgresql` (prefer Bookworm over Alpine for CVE posture) |
