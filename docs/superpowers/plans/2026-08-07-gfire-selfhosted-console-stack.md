# Console Compose Stack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship env rename + `run/docker-compose/console/` (3 gfire peers + BFF + SPA + dual Postgres 18.4 Bookworm) per the console-stack design, with wrapper/`release-check` support.

**Architecture:** One operator `.env` under `GFIRE_STACK_HOST_DATA`. Minimal stays one engine node; console defines named services `gfire-1`…`gfire-3` sharing engine storage. BFF proxies to `gfire-1`. BFF migrations extracted from the backend image into host data (distroless has no shell).

**Tech Stack:** Docker Compose v2, bash wrapper, official `postgres:18.4-bookworm`, GHCR app images, `migrate/migrate`.

**Spec:** [../specs/2026-08-07-gfire-selfhosted-console-stack-design.md](../specs/2026-08-07-gfire-selfhosted-console-stack-design.md)

## Global Constraints

- English only in repo artifacts
- Env prefixes: `GFIRE_STACK_*` · `GFIRE_*` · `GFIREUI_*` · `GFIREUI_BACKEND_*` · `PUBLIC_GFIREUI_*`
- Canonical host data: `GFIRE_STACK_HOST_DATA` (alias `GFIRE_HOST_DATA` one release, stderr warn)
- Postgres image: `postgres:18.4-bookworm`; bind → `/var/lib/postgresql`
- Console: exactly three named peers `gfire-1`…`gfire-3` (not `deploy.replicas`)
- No Traefik / metrics / observability in this plan
- Deny-all + whitelist `.gitignore`; never commit live `.env` or `data/release-check/`
- Commits: show message, wait for **explicit user approval** before `git commit`
- Product GHCR for `gfireui` / `gfireui-backend` may land in parallel; compose must accept `*_IMAGE` overrides for local tags

## File map

| Path | Responsibility |
|------|----------------|
| `run/common/.env.example` | Minimal template (renamed vars + Redis/ValKey comments) |
| `run/docker-compose/minimal/docker-compose.yml` | Interpolate `GFIRE_STACK_HOST_DATA` + `GFIRE_POSTGRES_*` + `GFIRE_REDIS_*` / `GFIRE_VALKEY_*` |
| `run/scripts/compose-stack.sh` | Resolve host data; stacks `minimal` \| `console` |
| `run/scripts/extract-gfireui-migrations.sh` | `docker create` + `docker cp` migrations → `${GFIRE_STACK_HOST_DATA}/migrations-ui` |
| `run/docker-compose/console/.env.example` | Full console pins |
| `run/docker-compose/console/docker-compose.yml` | Full stack YAML |
| `run/docker-compose/console/README.md` | Operator runbook + smoke |
| `Makefile` | `release-check` for minimal + console `config` |
| `README.md`, `AGENTS.md`, `run/**/README.md`, `ROADMAP.md`, `CHANGELOG.md` | Docs sync |
| Specs | Mark console design **Approved**; keep parent design aligned |

---

### Task 1: Rename host data + Postgres/Redis env in minimal

**Files:**
- Modify: `run/common/.env.example`
- Modify: `run/docker-compose/minimal/docker-compose.yml`
- Modify: `run/docker-compose/README.md` (var names only where they describe minimal)

**Interfaces:**
- Produces: compose interpolates `GFIRE_STACK_HOST_DATA`, `GFIRE_POSTGRES_DB|USER|PASSWORD|HOST_PORT`, `GFIRE_REDIS_HOST_PORT`, `GFIRE_VALKEY_HOST_PORT`
- Consumes: existing minimal service layout (1× `gfire`, profiles redis/valkey)

- [ ] **Step 1: Rewrite `run/common/.env.example` header + vars**

Replace host-data name with `GFIRE_STACK_HOST_DATA`. Document deprecated `GFIRE_HOST_DATA`. Use `GFIRE_POSTGRES_*`. Expand commented Redis/ValKey block exactly as in design §5.3. Keep magro (no UI/BFF keys). Keep `postgres:18.4-bookworm` note.

- [ ] **Step 2: Update minimal compose interpolations**

In `run/docker-compose/minimal/docker-compose.yml`:

- All `${GFIRE_HOST_DATA` → `${GFIRE_STACK_HOST_DATA` (error messages too)
- `POSTGRES_DB` → `GFIRE_POSTGRES_DB` (and USER/PASSWORD/HOST_PORT)
- healthcheck `-U ${GFIRE_POSTGRES_USER:-gfire} -d ${GFIRE_POSTGRES_DB:-gfire}`
- `REDIS_HOST_PORT` → `GFIRE_REDIS_HOST_PORT`
- `VALKEY_HOST_PORT` → `GFIRE_VALKEY_HOST_PORT`
- Wire optional engine redis env when present:

```yaml
      GFIRE_STORAGE_REDIS_ADDR: ${GFIRE_STORAGE_REDIS_ADDR:-}
      GFIRE_STORAGE_REDIS_PASSWORD: ${GFIRE_STORAGE_REDIS_PASSWORD:-}
      GFIRE_STORAGE_REDIS_DB: ${GFIRE_STORAGE_REDIS_DB:-0}
```

(Empty addr is fine when backend is postgres.)

- [ ] **Step 3: Validate compose config with disposable data dir**

```bash
cd /Volumes/Data/addlink/github/gfire-selfhosted
mkdir -p data/release-check/postgres data/release-check/redis data/release-check/valkey
sed 's|^GFIRE_STACK_HOST_DATA=.*|GFIRE_STACK_HOST_DATA='"$(pwd)"'/data/release-check|' \
  run/common/.env.example > data/release-check/.env
# If template still has only GFIRE_HOST_DATA during WIP, fix template first then re-sed.
docker compose --env-file data/release-check/.env \
  -f run/docker-compose/minimal/docker-compose.yml config >/dev/null
docker compose --env-file data/release-check/.env \
  -f run/docker-compose/minimal/docker-compose.yml --profile redis config >/dev/null
docker compose --env-file data/release-check/.env \
  -f run/docker-compose/minimal/docker-compose.yml --profile valkey config >/dev/null
```

Expected: exit 0, no unresolved required vars.

- [ ] **Step 4: Propose commit (do not commit until user approves)**

Proposed message:

```
Align minimal Compose env with GFIRE_STACK_* prefixes

Rename host data and Postgres/Redis port vars; document Redis/ValKey
optional block; keep postgres:18.4-bookworm mount path.
```

---

### Task 2: Wrapper + Makefile resolve `GFIRE_STACK_HOST_DATA`

**Files:**
- Modify: `run/scripts/compose-stack.sh`
- Modify: `Makefile`
- Modify: `AGENTS.md`, `README.md`, `run/README.md`, `run/docker-compose/README.md` (HOST_DATA → STACK)

**Interfaces:**
- Produces: `resolve_stack_host_data` behavior — export `GFIRE_STACK_HOST_DATA`; warn on alias
- Consumes: Task 1 env file location `${GFIRE_STACK_HOST_DATA}/.env`

- [ ] **Step 1: Update `compose-stack.sh` resolution**

After parsing `--data-dir`, implement:

```bash
if [[ -n "${DATA_DIR}" ]]; then
  export GFIRE_STACK_HOST_DATA="$DATA_DIR"
fi

if [[ -z "${GFIRE_STACK_HOST_DATA:-}" && -n "${GFIRE_HOST_DATA:-}" ]]; then
  echo "warning: GFIRE_HOST_DATA is deprecated; use GFIRE_STACK_HOST_DATA" >&2
  export GFIRE_STACK_HOST_DATA="${GFIRE_HOST_DATA}"
fi

if [[ -z "${GFIRE_STACK_HOST_DATA:-}" ]]; then
  echo "error: set GFIRE_STACK_HOST_DATA or pass --data-dir DIR" >&2
  ...
  exit 1
fi

# Keep GFIRE_HOST_DATA in sync for any leftover interpolations during transition
export GFIRE_HOST_DATA="${GFIRE_STACK_HOST_DATA}"

MAIN_ENV="${GFIRE_STACK_HOST_DATA}/.env"
```

Update `usage()` text: stacks list still `minimal` only until Task 5; document both env names.

`--data-dir` must set `GFIRE_STACK_HOST_DATA` (not only old name).

- [ ] **Step 2: Update Makefile `release-check`**

```makefile
RELEASE_CHECK_DATA := data/release-check

release-check:
	@command -v docker >/dev/null 2>&1 || { echo "docker not found"; exit 1; }
	@mkdir -p "$(RELEASE_CHECK_DATA)/postgres" "$(RELEASE_CHECK_DATA)/redis" "$(RELEASE_CHECK_DATA)/valkey"
	@sed 's|^GFIRE_STACK_HOST_DATA=.*|GFIRE_STACK_HOST_DATA=$(CURDIR)/$(RELEASE_CHECK_DATA)|' \
		"$(ENV_EXAMPLE)" > "$(RELEASE_CHECK_DATA)/.env"
	@echo "release-check: docker compose config (minimal)..."
	@docker compose --env-file "$(RELEASE_CHECK_DATA)/.env" -f "$(COMPOSE_MINIMAL)" config >/dev/null
	@echo "release-check: docker compose config (minimal + redis profile)..."
	@docker compose --env-file "$(RELEASE_CHECK_DATA)/.env" -f "$(COMPOSE_MINIMAL)" --profile redis config >/dev/null
	@echo "release-check: docker compose config (minimal + valkey profile)..."
	@docker compose --env-file "$(RELEASE_CHECK_DATA)/.env" -f "$(COMPOSE_MINIMAL)" --profile valkey config >/dev/null
	@echo "release-check: compose-stack.sh help..."
	@./run/scripts/compose-stack.sh --help >/dev/null
	@echo "release-check passed."
```

Ensure `.env.example` line matching `^GFIRE_STACK_HOST_DATA=` exists (Task 1).

- [ ] **Step 3: Docs pass for rename**

Replace operator-facing `GFIRE_HOST_DATA` with `GFIRE_STACK_HOST_DATA` in README/AGENTS/run docs; one-line note that old name still works for one release.

- [ ] **Step 4: Run checks**

```bash
make release-check
GFIRE_HOST_DATA="$(pwd)/data/release-check" ./run/scripts/compose-stack.sh minimal config >/dev/null
```

Expected: warning on deprecated name; config succeeds; `make release-check` passes.

- [ ] **Step 5: Propose commit**

```
Prefer GFIRE_STACK_HOST_DATA in wrapper and docs

Keep GFIRE_HOST_DATA as deprecated alias with warning; fix release-check sed.
```

---

### Task 3: Extract BFF migrations script

**Files:**
- Create: `run/scripts/extract-gfireui-migrations.sh`
- Modify: `.gitignore` only if a new allow pattern is required (script under `run/` already allowed)

**Interfaces:**
- Produces: directory `${GFIRE_STACK_HOST_DATA}/migrations-ui` with `*.up.sql` / `*.down.sql`
- Consumes: image ref from `GFIREUI_BACKEND_IMAGE` or `ghcr.io/hrodrig/gfireui-backend:${GFIREUI_BACKEND_VERSION}`

- [ ] **Step 1: Write script**

```bash
#!/usr/bin/env bash
# Extract /app/migrations from gfireui-backend image into HOST_DATA/migrations-ui.
set -euo pipefail

if [[ -z "${GFIRE_STACK_HOST_DATA:-}" && -n "${GFIRE_HOST_DATA:-}" ]]; then
  echo "warning: GFIRE_HOST_DATA is deprecated; use GFIRE_STACK_HOST_DATA" >&2
  GFIRE_STACK_HOST_DATA="${GFIRE_HOST_DATA}"
fi
: "${GFIRE_STACK_HOST_DATA:?set GFIRE_STACK_HOST_DATA}"

IMAGE="${GFIREUI_BACKEND_IMAGE:-}"
if [[ -z "$IMAGE" ]]; then
  VER="${GFIREUI_BACKEND_VERSION:?set GFIREUI_BACKEND_VERSION or GFIREUI_BACKEND_IMAGE}"
  IMAGE="ghcr.io/hrodrig/gfireui-backend:${VER}"
fi

OUT="${GFIRE_STACK_HOST_DATA}/migrations-ui"
mkdir -p "$OUT"
cid="$(docker create "$IMAGE")"
trap 'docker rm -f "$cid" >/dev/null 2>&1 || true' EXIT
docker cp "$cid:/app/migrations/." "$OUT/"
echo "extracted migrations → ${OUT}"
```

`chmod +x` the script.

- [ ] **Step 2: Dry-run when image available**

```bash
export GFIRE_STACK_HOST_DATA=/tmp/gfire-stack-test
export GFIREUI_BACKEND_IMAGE=gfireui-backend:0.1.0   # or GHCR tag when published
mkdir -p "$GFIRE_STACK_HOST_DATA"
./run/scripts/extract-gfireui-migrations.sh
ls "$GFIRE_STACK_HOST_DATA/migrations-ui"
```

Expected: at least one `*_up.sql`. If image missing, document skip and continue — console `up` blocked until extract works; `compose config` does not need SQL files.

- [ ] **Step 3: Propose commit**

```
Add extract-gfireui-migrations.sh for console migrate volume

Copy /app/migrations from backend image into GFIRE_STACK_HOST_DATA.
```

---

### Task 4: Console `.env.example`

**Files:**
- Create: `run/docker-compose/console/.env.example`

**Interfaces:**
- Produces: full operator template per design §5.2 + §5.3
- Consumes: naming from Task 1

- [ ] **Step 1: Write template**

Include disclaimer header (same spirit as `run/common/.env.example`), copy steps for console, `GFIRE_STACK_GFIRE_NODES=3`, all pins from design §5.2, image override comments, Redis/ValKey commented block, note that `server_id` is set in compose YAML not `.env`.

- [ ] **Step 2: Propose commit**

```
Add console stack .env.example with multi-prefix pins

Document three-node proof, dual Postgres, and optional Redis/ValKey.
```

---

### Task 5: Console `docker-compose.yml` (3 peers + UI stack)

**Files:**
- Create: `run/docker-compose/console/docker-compose.yml`
- Create: `run/docker-compose/console/README.md`

**Interfaces:**
- Consumes: Task 4 env keys; Task 3 `migrations-ui` path
- Produces: project `gfire-console` services: `postgres`, `gfire-1`, `gfire-2`, `gfire-3`, `postgres-ui`, `migrate`, `backend`, `ui`, optional `redis`/`valkey`

- [ ] **Step 1: Write compose YAML**

Use same `x-logging` pattern as minimal. Key fragments:

```yaml
x-gfire-env: &gfire-env
  GFIRE_SERVER_HOST: "0.0.0.0"
  GFIRE_SERVER_PORT: "8080"
  GFIRE_STORAGE_BACKEND: ${GFIRE_STORAGE_BACKEND:-postgres}
  GFIRE_STORAGE_POSTGRES_DSN: ${GFIRE_STORAGE_POSTGRES_DSN:?set GFIRE_STORAGE_POSTGRES_DSN}
  GFIRE_AUTH_ENABLED: ${GFIRE_AUTH_ENABLED:-false}
  GFIRE_AUTH_TOKEN: ${GFIRE_AUTH_TOKEN:-}
  GFIRE_SERVER_WORKERS: ${GFIRE_SERVER_WORKERS:-4}
  GFIRE_STORAGE_REDIS_ADDR: ${GFIRE_STORAGE_REDIS_ADDR:-}
  GFIRE_STORAGE_REDIS_PASSWORD: ${GFIRE_STORAGE_REDIS_PASSWORD:-}
  GFIRE_STORAGE_REDIS_DB: ${GFIRE_STORAGE_REDIS_DB:-0}

services:
  postgres:
    image: postgres:18.4-bookworm
    environment:
      POSTGRES_DB: ${GFIRE_POSTGRES_DB:-gfire}
      POSTGRES_USER: ${GFIRE_POSTGRES_USER:-gfire}
      POSTGRES_PASSWORD: ${GFIRE_POSTGRES_PASSWORD:?set GFIRE_POSTGRES_PASSWORD}
    ports:
      - "${GFIRE_POSTGRES_HOST_PORT:-5432}:5432"
    volumes:
      - ${GFIRE_STACK_HOST_DATA:?}/postgres:/var/lib/postgresql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${GFIRE_POSTGRES_USER:-gfire} -d ${GFIRE_POSTGRES_DB:-gfire}"]
      interval: 3s
      timeout: 3s
      retries: 10

  gfire-1:
    image: ${GFIRE_IMAGE:-ghcr.io/hrodrig/gfire:${GFIRE_VERSION:-v1.0.0}}
    command: ["server"]
    depends_on:
      postgres:
        condition: service_healthy
    ports:
      - "${GFIRE_HOST_PORT:-8080}:8080"
    environment:
      <<: *gfire-env
      GFIRE_SERVER_SERVER_ID: gfire-1

  gfire-2:
    image: ${GFIRE_IMAGE:-ghcr.io/hrodrig/gfire:${GFIRE_VERSION:-v1.0.0}}
    command: ["server"]
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      <<: *gfire-env
      GFIRE_SERVER_SERVER_ID: gfire-2

  gfire-3:
    image: ${GFIRE_IMAGE:-ghcr.io/hrodrig/gfire:${GFIRE_VERSION:-v1.0.0}}
    command: ["server"]
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      <<: *gfire-env
      GFIRE_SERVER_SERVER_ID: gfire-3

  postgres-ui:
    image: postgres:18.4-bookworm
    environment:
      POSTGRES_DB: ${GFIREUI_POSTGRES_DB:-gfireui}
      POSTGRES_USER: ${GFIREUI_POSTGRES_USERNAME:-gfireui}
      POSTGRES_PASSWORD: ${GFIREUI_POSTGRES_PASSWORD:?set GFIREUI_POSTGRES_PASSWORD}
    ports:
      - "${GFIREUI_POSTGRES_PORT:-5433}:5432"
    volumes:
      - ${GFIRE_STACK_HOST_DATA:?}/postgres-ui:/var/lib/postgresql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${GFIREUI_POSTGRES_USERNAME:-gfireui} -d ${GFIREUI_POSTGRES_DB:-gfireui}"]
      interval: 3s
      timeout: 3s
      retries: 10

  migrate:
    image: migrate/migrate:v4.18.1
    depends_on:
      postgres-ui:
        condition: service_healthy
    volumes:
      - ${GFIRE_STACK_HOST_DATA}/migrations-ui:/migrations:ro
    command:
      [
        "-path=/migrations",
        "-database=postgres://${GFIREUI_POSTGRES_USERNAME:-gfireui}:${GFIREUI_POSTGRES_PASSWORD}@postgres-ui:5432/${GFIREUI_POSTGRES_DB:-gfireui}?sslmode=disable",
        "up",
      ]

  backend:
    image: ${GFIREUI_BACKEND_IMAGE:-ghcr.io/hrodrig/gfireui-backend:${GFIREUI_BACKEND_VERSION:-v0.1.0}}
    depends_on:
      migrate:
        condition: service_completed_successfully
      gfire-1:
        condition: service_started
    ports:
      - "${GFIREUI_BACKEND_HOST_PORT:-8090}:8090"
    environment:
      GFIREUI_BACKEND_SERVER_ADDR: ":8090"
      GFIREUI_BACKEND_SERVER_CORS_ALLOWED_ORIGINS: "http://127.0.0.1:${GFIREUI_HOST_PORT:-8088},http://localhost:${GFIREUI_HOST_PORT:-8088}"
      GFIREUI_BACKEND_DATABASE_DSN: "postgres://${GFIREUI_POSTGRES_USERNAME:-gfireui}:${GFIREUI_POSTGRES_PASSWORD}@postgres-ui:5432/${GFIREUI_POSTGRES_DB:-gfireui}?sslmode=disable"
      GFIREUI_BACKEND_AUTH_JWT_SECRET: ${GFIREUI_BACKEND_AUTH_JWT_SECRET:?set GFIREUI_BACKEND_AUTH_JWT_SECRET}
      GFIREUI_BACKEND_AUTH_TOKEN_TTL: "24h"
      GFIREUI_BACKEND_GFIRE_BASE_URL: "http://gfire-1:8080"
      GFIREUI_BACKEND_GFIRE_TOKEN: ${GFIRE_AUTH_TOKEN:-}
      GFIREUI_BACKEND_BOOTSTRAP_ADMIN_EMAIL: ${GFIREUI_BACKEND_BOOTSTRAP_ADMIN_EMAIL:-admin@example.com}
      GFIREUI_BACKEND_BOOTSTRAP_ADMIN_PASSWORD: ${GFIREUI_BACKEND_BOOTSTRAP_ADMIN_PASSWORD:-adminadmin}
      GFIREUI_BACKEND_BOOTSTRAP_ADMIN_FIRST_NAME: ${GFIREUI_BACKEND_BOOTSTRAP_ADMIN_FIRST_NAME:-Admin}
      GFIREUI_BACKEND_BOOTSTRAP_ADMIN_LAST_NAME: ${GFIREUI_BACKEND_BOOTSTRAP_ADMIN_LAST_NAME:-User}

  ui:
    image: ${GFIREUI_IMAGE:-ghcr.io/hrodrig/gfireui:${GFIREUI_VERSION:-v0.1.0}}
    depends_on:
      - backend
    ports:
      - "${GFIREUI_HOST_PORT:-8088}:80"
    # If the SPA image listens on another port, adjust target and document in README.
    environment:
      # Browser-facing API base is usually baked at image build; document PUBLIC_GFIREUI_API_BASE
      # must match published BFF URL when building the image.
      PUBLIC_GFIREUI_API_BASE: ${PUBLIC_GFIREUI_API_BASE:-http://127.0.0.1:8090}
```

Add redis/valkey profile services mirroring minimal (paths under `GFIRE_STACK_HOST_DATA`, ports `GFIRE_REDIS_HOST_PORT` / `GFIRE_VALKEY_HOST_PORT`).

**Note on SPA port:** if the forthcoming `gfireui` image uses nginx on 8080 instead of 80, fix the target port in the same task once the image Dockerfile exists — README must state the published mapping.

- [ ] **Step 2: Write `run/docker-compose/console/README.md`**

Operator steps:

1. `export GFIRE_STACK_HOST_DATA=...`
2. `mkdir -p "$GFIRE_STACK_HOST_DATA"/{postgres,postgres-ui}`
3. Copy `.env.example` → `$GFIRE_STACK_HOST_DATA/.env` and edit
4. Apply **engine** migrations (link Band 1 helper / gfire repo) before or after peers up
5. `./run/scripts/extract-gfireui-migrations.sh` (env loaded from `.env` or exported)
6. `./run/scripts/compose-stack.sh console up -d`
7. Smoke checklist from design §8

Disclaimer link. No observability.

- [ ] **Step 3: `docker compose config` validation**

```bash
mkdir -p data/release-check/{postgres,postgres-ui,migrations-ui,redis,valkey}
# touch a dummy migration so migrate volume path exists for config
touch data/release-check/migrations-ui/.keep
sed 's|^GFIRE_STACK_HOST_DATA=.*|GFIRE_STACK_HOST_DATA='"$(pwd)"'/data/release-check|' \
  run/docker-compose/console/.env.example > data/release-check/.env
docker compose --env-file data/release-check/.env \
  -p gfire-console \
  -f run/docker-compose/console/docker-compose.yml config >/dev/null
```

Expected: exit 0. Confirm rendered services include `gfire-1`, `gfire-2`, `gfire-3`.

- [ ] **Step 4: Propose commit**

```
Add console Compose stack with three gfire peers

Wire BFF/SPA/dual Postgres 18.4-bookworm; migrate from HOST_DATA/migrations-ui.
```

---

### Task 6: Wire `console` into wrapper + release-check + roadmap

**Files:**
- Modify: `run/scripts/compose-stack.sh` (add `console` case)
- Modify: `Makefile`
- Modify: `README.md` (Pick a path row + short console section)
- Modify: `ROADMAP.md` (`GSH-030`, `GSH-031` notes / status when delivered)
- Modify: `CHANGELOG.md` under `[Unreleased]`
- Modify: `docs/superpowers/specs/2026-08-07-gfire-selfhosted-console-stack-design.md` → **Status: Approved**
- Modify: `docs/superpowers/plans/2026-08-07-gfire-selfhosted-bands.md` (Band 3 pointer to this plan)

**Interfaces:**
- Consumes: Task 5 compose path
- Produces: `./run/scripts/compose-stack.sh console config|up|…`

- [ ] **Step 1: Wrapper case**

```bash
  console)
    exec docker compose --env-file "$MAIN_ENV" -p gfire-console \
      -f "$ROOT/run/docker-compose/console/docker-compose.yml" \
      "$COMPOSE_SUBCMD" "$@"
    ;;
```

Update usage: known stacks `minimal | console`. Hint console `.env` from `run/docker-compose/console/.env.example`.

- [ ] **Step 2: Extend `make release-check`**

After minimal checks:

```makefile
	@mkdir -p "$(RELEASE_CHECK_DATA)/postgres-ui" "$(RELEASE_CHECK_DATA)/migrations-ui"
	@touch "$(RELEASE_CHECK_DATA)/migrations-ui/.keep"
	@sed 's|^GFIRE_STACK_HOST_DATA=.*|GFIRE_STACK_HOST_DATA=$(CURDIR)/$(RELEASE_CHECK_DATA)|' \
		run/docker-compose/console/.env.example > "$(RELEASE_CHECK_DATA)/.env.console"
	@echo "release-check: docker compose config (console)..."
	@docker compose --env-file "$(RELEASE_CHECK_DATA)/.env.console" -p gfire-console \
		-f run/docker-compose/console/docker-compose.yml config >/dev/null
```

Keep writing minimal `.env` as today for minimal checks (or regenerate both).

- [ ] **Step 3: Run full gate**

```bash
make release-check
```

Expected: `release-check passed.`

- [ ] **Step 4: Docs + ROADMAP + CHANGELOG + spec status**

- README: Compose console path; three peers called out
- ROADMAP: `GSH-030` / `GSH-031` → done when images+manifests land (if images still missing, leave ⬜ with note “manifests ready; blocked on GHCR”)
- CHANGELOG `[Unreleased]`: console layout + env rename + postgres 18.4-bookworm
- Spec status → Approved

- [ ] **Step 5: Propose commit**

```
Wire console stack into compose-stack and release-check

Document happy path; mark design approved; track GSH-030/031.
```

---

### Task 7: Dogfood smoke (when images exist)

**Files:** none required (operator runbook already in Task 5 README)

**Prereq:** GHCR (or local) tags for `gfire`, `gfireui-backend`, `gfireui`; engine migrations applied.

- [ ] **Step 1: Bring stack up outside the clone**

```bash
export GFIRE_STACK_HOST_DATA=/tmp/gfire-console-dogfood
mkdir -p "$GFIRE_STACK_HOST_DATA"/{postgres,postgres-ui}
cp run/docker-compose/console/.env.example "$GFIRE_STACK_HOST_DATA/.env"
# edit passwords + image pins / overrides
set -a && source "$GFIRE_STACK_HOST_DATA/.env" && set +a
./run/scripts/extract-gfireui-migrations.sh
# apply gfire postgres migrations (Band 1 helper or upstream)
./run/scripts/compose-stack.sh console up -d
```

- [ ] **Step 2: Smoke**

```bash
curl -sf "http://127.0.0.1:${GFIRE_HOST_PORT:-8080}/healthz"
docker compose --env-file "$GFIRE_STACK_HOST_DATA/.env" -p gfire-console \
  -f run/docker-compose/console/docker-compose.yml ps
# expect gfire-1,gfire-2,gfire-3 running
# login SPA; ops summary OK
```

Expected: design §8 checklist green.

- [ ] **Step 3: If SPA listen port wrong, fix compose target + commit proposal**

Only if dogfood proves port ≠ 80.

---

## Spec coverage checklist

| Spec requirement | Task |
|------------------|------|
| `GFIRE_STACK_HOST_DATA` + alias | 1–2 |
| Prefix convention / no bare `POSTGRES_*` | 1, 4, 5 |
| Redis/ValKey commented blocks | 1, 4 |
| `postgres:18.4-bookworm` + `/var/lib/postgresql` | 1, 5 (already partly in tree) |
| Console 3 named peers | 5 |
| BFF → `gfire-1` | 5 |
| Dual Postgres + migrate | 3, 5 |
| Templates per layout | 1, 4 |
| Wrapper `console` | 6 |
| Smoke / README | 5, 7 |
| No observability | all |

## Handoff

Plan saved. Two execution options:

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks  
2. **Inline Execution** — this session, `executing-plans`, checkpoints  

Which approach?
