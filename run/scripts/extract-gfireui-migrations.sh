#!/usr/bin/env bash
# Extract /app/migrations from gfireui-backend image into HOST_DATA/migrations-ui.
# Distroless runtime images have no shell — use docker create + docker cp.
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
