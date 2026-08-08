# Changelog

All notable changes to **gfire-selfhosted** (deployment manifests, docs, and tooling for this repository only) are documented here. For the **gfire** application, see [gfire CHANGELOG](https://github.com/hrodrig/gfire/blob/main/CHANGELOG.md).

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- **Pick a path / standalone:** document preferred native order — Homebrew → `.deb`/`.rpm` → install script/tarball → containers → **build from source last** (honest note: packages land when upstream publishes them).
- **`GFIRE_HOST_DATA` (gghstats-style):** live `.env` + Postgres bind-mount under a host directory outside the clone; `run/scripts/compose-stack.sh` requires it so `git pull` never flattens operator settings.
- **ROADMAP bands** (`GSH-*`): pending work (migrate helper, Helm, console, packaging sync, CI) tracked in `ROADMAP.md` + `docs/superpowers/plans/2026-08-07-gfire-selfhosted-bands.md`.
- **DISCLAIMER.md:** use at your own risk; operators responsible for their data; release of liability pointers from README / Compose / `.env.example`.
- Document **`redis/`** / **`valkey/`** under **`GFIRE_HOST_DATA`** (same as `postgres/`); VPS security pointer to [gghstats-selfhosted `run/vps-recommended`](https://github.com/hrodrig/gghstats-selfhosted/tree/main/run/vps-recommended).

## [0.1.0] - 2026-08-07

### Added

- Initial companion scaffold (family `*-selfhosted` layout).
- **Compose minimal:** `gfire` + PostgreSQL under `run/docker-compose/minimal/`.
- Optional Compose **redis** / **valkey** profiles.
- Standalone / `docker run` path docs under `run/`.
- Design note: `docs/superpowers/specs/2026-08-07-gfire-selfhosted-design.md`.
