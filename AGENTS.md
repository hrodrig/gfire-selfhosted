# Agent Guidelines (gfire-selfhosted)

- Use **English** for all project artifacts (code, comments, commit messages, docs, README).
- **Disclaimer:** keep **[DISCLAIMER.md](DISCLAIMER.md)** linked from README and operator entry points (Compose docs, `.env.example`, `compose-stack.sh` help). Do not weaken “use at your own risk / your data is your responsibility” language without explicit user approval.
- **Backlog:** track work in **[ROADMAP.md](ROADMAP.md)** (`GSH-*` band IDs). Do not invent parallel private todo lists for this repo.
- **Scope:** **gfire-selfhosted** owns deployment (Compose, Helm, **`run/`**, runbooks). Application source lives in:
  - **[gfire](https://github.com/hrodrig/gfire)** — headless job engine (binaries, GHCR)
  - **[gfireui-backend](https://github.com/hrodrig/gfireui-backend)** — ops console BFF
  - **[gfireui](https://github.com/hrodrig/gfireui)** — ops console SPA
- Follow **git flow**: work on `develop`; **`main`** for production snapshots; annotated tags **`v<semver>`** on **`main`** for infra releases (see root **`VERSION`**).
- **`VERSION`** (repository root): canonical **gfire-selfhosted** semver (`0.1.0` style, no `v`). When it changes, align the README **Version** badge and **CHANGELOG**. **`Chart.yaml` `version:`** (when present) tracks the Helm package only — bump when **`run/kubernetes/helm/gfire/`** changes materially.
- **`GFIRE_STACK_HOST_DATA` (required for Compose ops):** absolute directory **outside** this clone holding live **`.env`**, **`postgres/`** (and optional `postgres-ui/`, redis/valkey/config). Deprecated alias: **`GFIRE_HOST_DATA`** (one release). Updating this repo must never overwrite operator settings.
- Prefer **`./run/scripts/compose-stack.sh`** so Compose always uses **`${GFIRE_STACK_HOST_DATA}/.env`**. Stacks: `minimal` | `console`.
- Env prefixes: **`GFIRE_STACK_*`** (stack) · **`GFIRE_*`** (engine) · **`GFIREUI_*`** (SPA) · **`GFIREUI_BACKEND_*`** (BFF) · **`PUBLIC_GFIREUI_*`** (browser).
- **`GFIRE_VERSION`** / **`GFIREUI_*_VERSION`** pin OCI images. Not the same field as this repo’s **`VERSION`**.
- **`.gitignore`** is deny-all + whitelist. New root files need an explicit `!` allow rule. Ignore live **`.env`** and in-repo **`data/release-check/`**.
- Do not commit without first showing the proposed commit message and getting **explicit user approval**.
