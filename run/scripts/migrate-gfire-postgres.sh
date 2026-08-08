#!/usr/bin/env bash
# Apply gfire engine Postgres migrations for the pinned GFIRE_VERSION.
# Uses migrate/migrate OCI image + SQL from the matching gfire GitHub tag.
# See ROADMAP GSH-010.
set -euo pipefail

if [[ -z "${GFIRE_STACK_HOST_DATA:-}" && -n "${GFIRE_HOST_DATA:-}" ]]; then
  echo "warning: GFIRE_HOST_DATA is deprecated; use GFIRE_STACK_HOST_DATA" >&2
  GFIRE_STACK_HOST_DATA="${GFIRE_HOST_DATA}"
fi
: "${GFIRE_STACK_HOST_DATA:?set GFIRE_STACK_HOST_DATA}"

ENV_FILE="${GFIRE_STACK_HOST_DATA}/.env"
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

VER="${GFIRE_VERSION:?set GFIRE_VERSION (e.g. v1.0.0)}"
# Strip leading v for GitHub archive path consistency when needed.
TAG="$VER"
case "$TAG" in
  v*) ;;
  *) TAG="v${TAG}" ;;
esac

# Prefer an explicit host-reachable DSN for migrate (Compose service hostname
# "postgres" only resolves inside the compose network).
DSN="${GFIRE_MIGRATE_DSN:-}"
if [[ -z "$DSN" ]]; then
  USER="${GFIRE_POSTGRES_USER:-gfire}"
  PASS="${GFIRE_POSTGRES_PASSWORD:?set GFIRE_POSTGRES_PASSWORD or GFIRE_MIGRATE_DSN}"
  DB="${GFIRE_POSTGRES_DB:-gfire}"
  PORT="${GFIRE_POSTGRES_HOST_PORT:-5432}"
  DSN="postgres://${USER}:${PASS}@127.0.0.1:${PORT}/${DB}?sslmode=disable"
fi

MIGRATE_IMAGE="${GFIRE_MIGRATE_IMAGE:-migrate/migrate:v4.18.3}"
ARCHIVE_URL="https://github.com/hrodrig/gfire/archive/refs/tags/${TAG}.tar.gz"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "fetching migrations from ${ARCHIVE_URL}"
curl -fsSL "$ARCHIVE_URL" | tar -xz -C "$TMP"
MIG_DIR="$(echo "$TMP"/gfire-*/internal/storage/postgres/migrations)"
if [[ ! -d "$MIG_DIR" ]]; then
  echo "error: migrations dir not found in tag ${TAG}" >&2
  exit 1
fi

echo "migrate up → ${DSN%%@*}@…"
docker run --rm --network host \
  -v "${MIG_DIR}:/migrations:ro" \
  "$MIGRATE_IMAGE" \
  -path=/migrations \
  -database "$DSN" \
  up

echo "ok: gfire schema at ${TAG}"
