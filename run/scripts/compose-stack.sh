#!/usr/bin/env bash
# Wrapper for docker compose: always uses ${GFIRE_HOST_DATA}/.env from outside the clone.
# See run/README.md and run/docker-compose/README.md.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DATA_DIR=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [options] <stack> <compose-subcommand> [arguments...]

Run from any directory; compose files resolve relative to the repository clone.
Live secrets and durable data stay under GFIRE_HOST_DATA (outside the clone).

Stacks:
  minimal         run/docker-compose/minimal/docker-compose.yml (project: gfire)

Options:
  --data-dir DIR   Set GFIRE_HOST_DATA for this invocation
  -h, --help       Show this help

Environment:
  GFIRE_HOST_DATA   Required host directory containing .env plus durable dirs:
                    postgres/ (minimal), redis/ (--profile redis), valkey/ (--profile valkey)

Examples:
  export GFIRE_HOST_DATA=/home/gfire/gfire-data
  $(basename "$0") minimal up -d
  $(basename "$0") minimal pull
  $(basename "$0") minimal up -d --pull always
  $(basename "$0") minimal down
  $(basename "$0") minimal --profile redis up -d

Note: After changing GFIRE_VERSION in .env — pull, then up -d (not restart).
      restart keeps the same container image.

Disclaimer: use at your own risk. Your data and configuration are your
responsibility. See DISCLAIMER.md in the repository root.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --data-dir)
      [[ -n "${2:-}" ]] || {
        echo "error: --data-dir requires a path" >&2
        exit 1
      }
      DATA_DIR="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

if [[ -n "$DATA_DIR" ]]; then
  export GFIRE_HOST_DATA="$DATA_DIR"
fi

if [[ -z "${GFIRE_HOST_DATA:-}" ]]; then
  echo "error: set GFIRE_HOST_DATA or pass --data-dir DIR" >&2
  echo "hint: copy run/common/.env.example → \${GFIRE_HOST_DATA}/.env (outside the clone)" >&2
  usage >&2
  exit 1
fi

if [[ $# -lt 2 ]]; then
  echo "error: expected <stack> <compose-subcommand> [...]" >&2
  usage >&2
  exit 1
fi

STACK="$1"
shift
COMPOSE_SUBCMD="$1"
shift

MAIN_ENV="${GFIRE_HOST_DATA}/.env"
if [[ ! -f "$MAIN_ENV" ]]; then
  echo "error: missing ${MAIN_ENV}" >&2
  echo "hint: cp \"${ROOT}/run/common/.env.example\" \"${MAIN_ENV}\" && edit secrets" >&2
  exit 1
fi

case "$STACK" in
  minimal)
    exec docker compose --env-file "$MAIN_ENV" -p gfire \
      -f "$ROOT/run/docker-compose/minimal/docker-compose.yml" \
      "$COMPOSE_SUBCMD" "$@"
    ;;
  *)
    echo "error: unknown stack: $STACK (known: minimal)" >&2
    exit 1
    ;;
esac
