#!/bin/bash
# Full database backup using pg_dump

set -Eeuo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
BACKUP_DIR="${BACKUP_DIR:-$PROJECT_DIR/backups}"
RETENTION_COUNT="${RETENTION_COUNT:-7}"
COMPOSE_SERVICE="${COMPOSE_SERVICE:-postgres}"

cd "$PROJECT_DIR"

if [[ -f .env ]]; then
  set -a
  . ./.env
  set +a
fi

DB_NAME="${DB_NAME:-myapp_db}"
DB_USER="${DB_USER:-postgres}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/full_backup_${TIMESTAMP}.sql.gz"
TEMP_FILE="$BACKUP_FILE.tmp"

if ! [[ "$RETENTION_COUNT" =~ ^[1-9][0-9]*$ ]]; then
  echo "❌ RETENTION_COUNT must be a positive integer" >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"

if docker compose version >/dev/null 2>&1; then
  COMPOSE=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE=(docker-compose)
else
  echo "❌ Docker Compose is not available" >&2
  exit 1
fi

if ! "${COMPOSE[@]}" ps --status running "$COMPOSE_SERVICE" | tail -n +2 | grep -q .; then
  echo "❌ Compose service '$COMPOSE_SERVICE' is not running" >&2
  exit 1
fi

echo "[$(date)] Starting full database backup..."
echo "[$(date)] Backup file: $BACKUP_FILE"

trap 'rm -f "$TEMP_FILE"' EXIT

if ! "${COMPOSE[@]}" exec -T "$COMPOSE_SERVICE" pg_dump --clean --if-exists --format=plain -U "$DB_USER" "$DB_NAME" | gzip -c > "$TEMP_FILE"; then
  echo "❌ pg_dump failed" >&2
  exit 1
fi

if ! gzip -t "$TEMP_FILE"; then
  echo "❌ Backup gzip integrity check failed" >&2
  exit 1
fi

mv "$TEMP_FILE" "$BACKUP_FILE"
trap - EXIT

SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "[$(date)] ✅ Backup succeeded: $BACKUP_FILE ($SIZE)"

echo "[$(date)] Cleaning up old backups (keeping last $RETENTION_COUNT)..."
find "$BACKUP_DIR" -maxdepth 1 -type f -name 'full_backup_*.sql.gz' -printf '%T@ %p\n' | sort -nr | tail -n +$((RETENTION_COUNT + 1)) | cut -d' ' -f2- | xargs -r rm -f

echo "[$(date)] Backup process completed successfully"
