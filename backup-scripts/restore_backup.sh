#!/usr/bin/env bash
# Restore a PostgreSQL plain-SQL gzip backup.
# CAUTION: This drops and recreates the configured database.

set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
COMPOSE_SERVICE="${COMPOSE_SERVICE:-postgres}"
BACKUP_FILE="${1:-}"

if [[ -z "$BACKUP_FILE" ]]; then
  echo "❌ Usage: $0 <backup_file.sql.gz>" >&2
  exit 2
fi
if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "❌ Backup file not found: $BACKUP_FILE" >&2
  exit 1
fi
if ! gzip -t -- "$BACKUP_FILE"; then
  echo "❌ Backup gzip integrity check failed: $BACKUP_FILE" >&2
  exit 1
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
container_id=$("${COMPOSE[@]}" -f "$COMPOSE_FILE" ps -q "$COMPOSE_SERVICE")
if [[ -z "$container_id" ]] || [[ "$(docker inspect -f '{{.State.Running}}' "$container_id" 2>/dev/null || true)" != "true" ]]; then
  echo "❌ Compose service '$COMPOSE_SERVICE' is not running" >&2
  exit 1
fi

read_env() {
  local key="$1" value
  value=$("${COMPOSE[@]}" -f "$COMPOSE_FILE" exec -T "$COMPOSE_SERVICE" sh -c "printf '%s' \"\$$key\"")
  printf '%s' "$value"
}
DB_USER=$(read_env POSTGRES_USER)
DB_NAME=$(read_env POSTGRES_DB)
if [[ -z "$DB_USER" || -z "$DB_NAME" ]]; then
  echo "❌ Could not read POSTGRES_USER/POSTGRES_DB from service environment" >&2
  exit 1
fi

printf '⚠️  This will DROP and recreate database %q.\n' "$DB_NAME"
printf 'Backup: %s\n' "$BACKUP_FILE"
read -r -p "Type 'yes' to confirm: " confirm
if [[ "$confirm" != "yes" ]]; then
  echo "Restore cancelled"
  exit 0
fi

# Quote the identifier by doubling any embedded double quotes.
quoted_db_name=${DB_NAME//\"/\"\"}
"${COMPOSE[@]}" -f "$COMPOSE_FILE" exec -T "$COMPOSE_SERVICE" \
  psql -v ON_ERROR_STOP=1 -U "$DB_USER" -d postgres <<SQL
DROP DATABASE IF EXISTS "$quoted_db_name" WITH (FORCE);
CREATE DATABASE "$quoted_db_name";
SQL

echo "[$(date --iso-8601=seconds)] Restoring backup..."
gzip -dc -- "$BACKUP_FILE" | "${COMPOSE[@]}" -f "$COMPOSE_FILE" exec -T "$COMPOSE_SERVICE" \
  psql -v ON_ERROR_STOP=1 -U "$DB_USER" -d "$DB_NAME"

echo "[$(date --iso-8601=seconds)] Verifying restored tables..."
"${COMPOSE[@]}" -f "$COMPOSE_FILE" exec -T "$COMPOSE_SERVICE" \
  psql -v ON_ERROR_STOP=1 -U "$DB_USER" -d "$DB_NAME" -c \
  "SELECT 'users' AS table_name, COUNT(*) AS row_count FROM public.users UNION ALL SELECT 'products', COUNT(*) FROM public.products UNION ALL SELECT 'orders', COUNT(*) FROM public.orders;"

echo "[$(date --iso-8601=seconds)] ✅ Restore completed successfully"
