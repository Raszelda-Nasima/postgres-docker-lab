#!/bin/bash
# Restore database from a pg_dump gzip backup
# CAUTION: This drops and recreates the configured database.

set -Eeuo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
COMPOSE_SERVICE="${COMPOSE_SERVICE:-postgres}"
BACKUP_FILE="${1:-}"

cd "$PROJECT_DIR"

if [[ -f .env ]]; then
  set -a
  . ./.env
  set +a
fi

DB_NAME="${DB_NAME:-myapp_db}"
DB_USER="${DB_USER:-postgres}"

if [[ -z "$BACKUP_FILE" ]]; then
  echo "❌ Usage: $0 <backup_file.sql.gz>" >&2
  exit 1
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "❌ Backup file not found: $BACKUP_FILE" >&2
  exit 1
fi

if ! gzip -t "$BACKUP_FILE"; then
  echo "❌ Backup gzip integrity check failed: $BACKUP_FILE" >&2
  exit 1
fi

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

echo "[$(date)] ⚠️  Starting database restore from: $BACKUP_FILE"
echo "[$(date)] This will DROP the '$DB_NAME' database and recreate it!"

read -r -p "Type 'yes' to confirm: " confirm
if [[ "$confirm" != "yes" ]]; then
  echo "Restore cancelled"
  exit 0
fi

echo "[$(date)] Dropping existing database..."
"${COMPOSE[@]}" exec -T "$COMPOSE_SERVICE" psql -v ON_ERROR_STOP=1 -U "$DB_USER" -d postgres <<SQL
DROP DATABASE IF EXISTS "$DB_NAME";
CREATE DATABASE "$DB_NAME";
SQL

echo "[$(date)] Restoring data from backup..."
gzip -dc "$BACKUP_FILE" | "${COMPOSE[@]}" exec -T "$COMPOSE_SERVICE" psql -v ON_ERROR_STOP=1 -U "$DB_USER" -d "$DB_NAME"

echo "[$(date)] Verifying restore..."
"${COMPOSE[@]}" exec -T "$COMPOSE_SERVICE" psql -v ON_ERROR_STOP=1 -U "$DB_USER" -d "$DB_NAME" -c "SELECT 'users' AS table_name, COUNT(*) AS row_count FROM public.users UNION ALL SELECT 'products', COUNT(*) FROM public.products UNION ALL SELECT 'orders', COUNT(*) FROM public.orders;"

echo "[$(date)] ✅ Database restore completed successfully"
