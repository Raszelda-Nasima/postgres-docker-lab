#!/usr/bin/env bash
# Full PostgreSQL backup via the Docker Compose service.

set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
COMPOSE_SERVICE="${COMPOSE_SERVICE:-postgres}"
BACKUP_DIR="${BACKUP_DIR:-$PROJECT_DIR/backups}"
RETENTION_COUNT="${RETENTION_COUNT:-7}"

if [[ "$BACKUP_DIR" != /* ]]; then
  BACKUP_DIR="$PROJECT_DIR/$BACKUP_DIR"
fi

if ! [[ "$RETENTION_COUNT" =~ ^[1-9][0-9]*$ ]]; then
  echo "❌ RETENTION_COUNT must be a positive integer (got: $RETENTION_COUNT)" >&2
  exit 2
fi

if docker compose version >/dev/null 2>&1; then
  COMPOSE=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE=(docker-compose)
else
  echo "❌ Docker Compose was not found" >&2
  exit 1
fi

cd "$PROJECT_DIR"
mkdir -p "$BACKUP_DIR"

container_id=$("${COMPOSE[@]}" -f "$COMPOSE_FILE" ps -q "$COMPOSE_SERVICE")
if [[ -z "$container_id" ]] || [[ "$(docker inspect -f '{{.State.Running}}' "$container_id" 2>/dev/null || true)" != "true" ]]; then
  echo "❌ Compose service '$COMPOSE_SERVICE' is not running" >&2
  exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/full_backup_${TIMESTAMP}.sql.gz"
TEMP_FILE=$(mktemp "$BACKUP_DIR/.full_backup_${TIMESTAMP}.XXXXXX.tmp")
trap 'rm -f -- "$TEMP_FILE"' EXIT

echo "[$(date --iso-8601=seconds)] Starting PostgreSQL backup"
echo "[$(date --iso-8601=seconds)] Target: $BACKUP_FILE"

# Read credentials/database name from the running service's POSTGRES_* environment.
"${COMPOSE[@]}" -f "$COMPOSE_FILE" exec -T "$COMPOSE_SERVICE" \
  sh -c 'exec pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' | gzip -c > "$TEMP_FILE"

gzip -t "$TEMP_FILE"
mv -- "$TEMP_FILE" "$BACKUP_FILE"
trap - EXIT

size=$(du -h -- "$BACKUP_FILE" | cut -f1)
echo "[$(date --iso-8601=seconds)] Backup succeeded ($size)"

# Generated backup names are timestamp-sortable; retain the newest N valid completed files.
shopt -s nullglob
backups=("$BACKUP_DIR"/full_backup_*.sql.gz)
if (( ${#backups[@]} > RETENTION_COUNT )); then
  mapfile -t backups < <(printf '%s\n' "${backups[@]}" | LC_ALL=C sort -r)
  for ((i = RETENTION_COUNT; i < ${#backups[@]}; i++)); do
    echo "[$(date --iso-8601=seconds)] Removing expired backup: ${backups[i]}"
    rm -f -- "${backups[i]}"
  done
fi

echo "[$(date --iso-8601=seconds)] Backup complete; retention count: $RETENTION_COUNT"
